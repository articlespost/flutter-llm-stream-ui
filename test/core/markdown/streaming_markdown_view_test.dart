import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm_stream_ui/src/core/markdown/incremental_markdown_document.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/streaming_markdown_view.dart';

void main() {
  late IncrementalMarkdownDocument document;
  late ValueNotifier<MarkdownSnapshot> snapshot;

  setUp(() {
    document = IncrementalMarkdownDocument();
    snapshot = ValueNotifier(MarkdownSnapshot.empty);
  });

  tearDown(() => snapshot.dispose());

  Future<void> pumpView(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StreamingMarkdownView(snapshot: snapshot),
        ),
      ),
    ),
  );

  void append(String chunk) {
    document.append(chunk);
    snapshot.value = document.snapshot;
  }

  testWidgets('reaproveita a mesma instância de widget dos blocos congelados', (
    tester,
  ) async {
    await pumpView(tester);
    append('# Título\n\nPrimeiro parágrafo.\n\nSegundo ');
    await tester.pump();

    final firstHeading = tester.widget(
      find.byKey(const ValueKey('markdown-frozen-0')),
    );
    final firstParagraph = tester.widget(
      find.byKey(const ValueKey('markdown-frozen-1')),
    );

    append('parágrafo crescendo');
    await tester.pump();
    append(' até terminar.\n\nTerceiro.');
    await tester.pump();

    expect(
      identical(
        tester.widget(find.byKey(const ValueKey('markdown-frozen-0'))),
        firstHeading,
      ),
      isTrue,
    );
    expect(
      identical(
        tester.widget(find.byKey(const ValueKey('markdown-frozen-1'))),
        firstParagraph,
      ),
      isTrue,
    );
    expect(
      find.text('Segundo parágrafo crescendo até terminar.'),
      findsOneWidget,
    );
  });

  testWidgets('mostra o cursor só enquanto a resposta não termina', (
    tester,
  ) async {
    await pumpView(tester);
    append('Texto em andamento');
    await tester.pump();
    expect(find.byKey(const ValueKey('markdown-tail')), findsOneWidget);

    document.complete();
    snapshot.value = document.snapshot;
    await tester.pump();

    expect(find.byKey(const ValueKey('markdown-tail')), findsNothing);
    expect(find.text('Texto em andamento'), findsOneWidget);
  });
}
