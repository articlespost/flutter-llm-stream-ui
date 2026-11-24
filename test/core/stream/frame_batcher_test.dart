import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm_stream_ui/src/core/stream/frame_batcher.dart';

void main() {
  testWidgets('agrupa todos os chunks recebidos entre dois frames', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final batches = <String>[];
    final batcher = FrameBatcher(onFlush: batches.add);
    addTearDown(batcher.dispose);

    batcher
      ..add('Ol')
      ..add('á, ')
      ..add('mundo');
    expect(batches, isEmpty);

    await tester.pump();
    expect(batches, ['Olá, mundo']);

    batcher.add('!');
    await tester.pump();
    expect(batches, ['Olá, mundo', '!']);
  });

  testWidgets('flush entrega o restante imediatamente', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final batches = <String>[];
    final batcher = FrameBatcher(onFlush: batches.add);
    addTearDown(batcher.dispose);

    batcher
      ..add('fim')
      ..flush();

    expect(batches, ['fim']);
    await tester.pump();
    expect(batches, ['fim']);
  });

  testWidgets('não entrega nada depois do dispose', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final batches = <String>[];
    final batcher = FrameBatcher(onFlush: batches.add)..add('perdido');

    batcher.dispose();
    await tester.pump();

    expect(batches, isEmpty);
  });
}
