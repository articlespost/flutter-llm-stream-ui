import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm_stream_ui/src/app.dart';
import 'package:llm_stream_ui/src/core/di/app_container.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/code_block_view.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/streaming_markdown_view.dart';
import 'package:llm_stream_ui/src/features/chat/data/datasource/llm_stream_data_source.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/screens/chat_screen.strings.dart';

import '../../../../helpers/pump_until.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      LlmStreamApp(
        container: AppContainer(
          dataSource: const LlmStreamDataSource(
            chunkInterval: Duration(milliseconds: 1),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  bool isStreaming(WidgetTester tester) =>
      find.byIcon(Icons.stop_rounded).evaluate().isNotEmpty;

  Future<void> tapSuggestion(WidgetTester tester, String suggestion) async {
    final chip = find.text(suggestion);
    await tester.ensureVisible(chip);
    await tester.pump();
    await tester.tap(chip);
    await tester.pump();
  }

  testWidgets('modo otimizado renderiza a resposta em Markdown até o fim', (
    tester,
  ) async {
    await pumpApp(tester);

    await tapSuggestion(tester, ChatScreenStrings.suggestions.first);
    expect(isStreaming(tester), isTrue);
    expect(find.byType(StreamingMarkdownView), findsOneWidget);

    await pumpUntil(tester, () => !isStreaming(tester));
    await tester.pump();

    expect(find.text('Streams em Dart, sem mistério'), findsOneWidget);
    expect(find.byType(CodeBlockView), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
    expect(find.byTooltip(ChatScreenStrings.copy), findsOneWidget);
  });

  testWidgets('modo ingênuo produz o mesmo conteúdo final', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text(ChatScreenStrings.naive));
    await tester.pump();
    await tapSuggestion(tester, ChatScreenStrings.suggestions.first);
    expect(find.byType(StreamingMarkdownView), findsNothing);

    await pumpUntil(tester, () => !isStreaming(tester));
    await tester.pump();

    expect(find.text('Streams em Dart, sem mistério'), findsOneWidget);
    expect(find.byType(CodeBlockView), findsOneWidget);
  });

  testWidgets(
    'seletores de modo e de fonte ficam desabilitados durante o streaming',
    (tester) async {
      await pumpApp(tester);

      await tapSuggestion(tester, ChatScreenStrings.suggestions.first);

      final selectors = tester.widgetList<SegmentedButton<Object>>(
        find.byWidgetPredicate((widget) => widget is SegmentedButton),
      );
      expect(selectors, hasLength(2));
      for (final selector in selectors) {
        expect(selector.onSelectionChanged, isNull);
      }

      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump();
      expect(isStreaming(tester), isFalse);
    },
  );

  testWidgets(
    'fonte simulada avisa que só responde aos 4 temas fixos e o Gemini fica desabilitado sem proxy',
    (tester) async {
      await pumpApp(tester);

      expect(find.text(ChatScreenStrings.simulatedNotice), findsOneWidget);
      expect(find.text(ChatScreenStrings.geminiSetupNotice), findsOneWidget);
      for (final suggestion in ChatScreenStrings.suggestions) {
        expect(find.text(suggestion), findsOneWidget);
      }

      await tester.tap(find.text(ChatScreenStrings.geminiSource));
      await tester.pump();

      expect(find.text(ChatScreenStrings.simulatedNotice), findsOneWidget);
      expect(find.text(ChatScreenStrings.geminiNotice), findsNothing);
    },
  );
}
