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

  testWidgets('modo otimizado renderiza a resposta em Markdown até o fim', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text(ChatScreenStrings.suggestions.first));
    await tester.pump();
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
    await tester.tap(find.text(ChatScreenStrings.suggestions.first));
    await tester.pump();
    expect(find.byType(StreamingMarkdownView), findsNothing);

    await pumpUntil(tester, () => !isStreaming(tester));
    await tester.pump();

    expect(find.text('Streams em Dart, sem mistério'), findsOneWidget);
    expect(find.byType(CodeBlockView), findsOneWidget);
  });

  testWidgets('seletor de modo fica desabilitado durante o streaming', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text(ChatScreenStrings.suggestions.first));
    await tester.pump();

    final selector = tester.widget<SegmentedButton<Object>>(
      find.byWidgetPredicate((widget) => widget is SegmentedButton),
    );
    expect(selector.onSelectionChanged, isNull);

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();
    expect(isStreaming(tester), isFalse);
  });
}
