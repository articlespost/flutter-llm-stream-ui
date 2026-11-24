import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm_stream_ui/src/features/chat/data/datasource/llm_stream_data_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/chat_message.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_event.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_failure.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/response_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/search_grounding.dart';
import 'package:llm_stream_ui/src/features/chat/data/models/completion_request_model.dart';
import 'package:llm_stream_ui/src/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:llm_stream_ui/src/features/chat/data/repositories/i_chat_repository.dart';
import 'package:llm_stream_ui/src/features/chat/data/services/chat_service.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/controllers/chat_controller.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/state/chat_state.dart';

import '../../../../helpers/pump_until.dart';

class _GeminiRepository implements IChatRepository {
  _GeminiRepository(this.events);

  final Stream<CompletionEvent> Function() events;
  final List<ResponseSource> requestedSources = [];

  @override
  bool isAvailable(ResponseSource source) => true;

  @override
  Stream<CompletionEvent> streamCompletion(
    String prompt, {
    required ResponseSource source,
  }) {
    requestedSources.add(source);
    return events();
  }
}

void main() {
  const prompt = 'Explique streams em Dart';
  const dataSource = LlmStreamDataSource(
    chunkInterval: Duration(milliseconds: 1),
  );

  late String expectedText;

  setUpAll(() async {
    expectedText = await const LlmStreamDataSource(chunkInterval: Duration.zero)
        .streamCompletion(const CompletionRequestModel(prompt: prompt))
        .join();
  });

  Future<ChatController> buildController(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    final controller = ChatController(
      const ChatService(ChatRepositoryImpl(dataSource)),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  testWidgets(
    'modo otimizado: a lista de mensagens só muda no envio e no fim',
    (tester) async {
      final controller = await buildController(tester);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.send(prompt);
      expect(controller.value.messages.map((message) => message.role), [
        MessageRole.user,
        MessageRole.assistant,
      ]);
      expect(controller.value.isStreaming, isTrue);

      await pumpUntil(tester, () => !controller.value.isStreaming);

      expect(notifications, 2);
      expect(controller.value.messages.last.text, expectedText);
      final snapshot = controller.snapshotFor(
        controller.value.messages.last.id,
      )!;
      expect(snapshot.value.isComplete, isTrue);
      expect(snapshot.value.tailBlocks, isEmpty);
    },
  );

  testWidgets('modo ingênuo: o estado da tela muda a cada chunk', (
    tester,
  ) async {
    final controller = await buildController(tester);
    controller.changeStrategy(RenderingStrategy.naive);
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.send(prompt);
    await pumpUntil(tester, () => !controller.value.isStreaming);

    expect(notifications, greaterThan(100));
    expect(controller.value.messages.last.text, expectedText);
    expect(
      controller.snapshotFor(controller.value.messages.last.id),
      isNotNull,
    );
  });

  testWidgets('parar mantém o texto parcial e encerra o streaming', (
    tester,
  ) async {
    final controller = await buildController(tester);

    controller.send(prompt);
    await tester.pump(const Duration(milliseconds: 40));
    final stopping = controller.stop();
    await tester.pump(const Duration(milliseconds: 16));
    await stopping;

    final partial = controller.value.messages.last.text;
    expect(controller.value.isStreaming, isFalse);
    expect(partial, isNotEmpty);
    expect(expectedText.startsWith(partial), isTrue);
    expect(partial.length, lessThan(expectedText.length));
  });

  testWidgets('ignora prompt vazio e não troca de modo durante o streaming', (
    tester,
  ) async {
    final controller = await buildController(tester);

    controller.send('   ');
    expect(controller.value.messages, isEmpty);

    controller
      ..send(prompt)
      ..changeStrategy(RenderingStrategy.naive);
    expect(controller.value.strategy, RenderingStrategy.optimized);

    await pumpUntil(tester, () => !controller.value.isStreaming);
  });

  group('fonte Gemini', () {
    final grounding = SearchGrounding(
      sources: [
        GroundingSource(
          title: 'flutter.dev',
          uri: Uri.parse('https://flutter.dev'),
        ),
      ],
      searchQueries: const ['o que é flutter'],
    );

    Future<(ChatController, _GeminiRepository)> buildGemini(
      WidgetTester tester,
      Stream<CompletionEvent> Function() events,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final repository = _GeminiRepository(events);
      final controller = ChatController(ChatService(repository))
        ..changeSource(ResponseSource.gemini);
      addTearDown(controller.dispose);
      return (controller, repository);
    }

    testWidgets(
      'guarda as fontes da busca na mensagem quando a resposta termina',
      (tester) async {
        final (controller, repository) = await buildGemini(
          tester,
          () => Stream.fromIterable([
            const TextDelta('Flutter é '),
            const TextDelta('um SDK.'),
            GroundingReceived(grounding),
          ]),
        );

        controller.send('O que é Flutter?');
        expect(controller.value.messages.last.grounding, isNull);
        await pumpUntil(tester, () => !controller.value.isStreaming);

        expect(repository.requestedSources, [ResponseSource.gemini]);
        expect(controller.value.messages.last.text, 'Flutter é um SDK.');
        expect(controller.value.messages.last.grounding, grounding);
        expect(controller.value.failure, isNull);
      },
    );

    testWidgets('expõe a falha no estado e mantém o texto parcial', (
      tester,
    ) async {
      final (controller, _) = await buildGemini(tester, () async* {
        yield const TextDelta('Começo');
        throw const CompletionFailure(CompletionFailureReason.quotaExceeded);
      });

      controller.send('Oi');
      await pumpUntil(tester, () => !controller.value.isStreaming);

      expect(
        controller.value.failure,
        const CompletionFailure(CompletionFailureReason.quotaExceeded),
      );
      expect(controller.value.messages.last.text, 'Começo');

      controller.send('De novo');
      expect(controller.value.failure, isNull);
      await pumpUntil(tester, () => !controller.value.isStreaming);
    });

    testWidgets('não troca para uma fonte indisponível', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final controller = ChatController(
        const ChatService(ChatRepositoryImpl(dataSource)),
      );
      addTearDown(controller.dispose);

      controller.changeSource(ResponseSource.gemini);

      expect(controller.isAvailable(ResponseSource.gemini), isFalse);
      expect(controller.value.source, ResponseSource.simulated);
    });
  });
}
