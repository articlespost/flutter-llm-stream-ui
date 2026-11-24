import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:llm_stream_ui/src/core/network/sse_decoder.dart';

Stream<List<int>> _bytesOf(List<String> parts) =>
    Stream.fromIterable(parts.map(utf8.encode));

void main() {
  test('separa eventos, junta linhas de data e lê o nome do evento', () async {
    final events = await decodeSse(
      _bytesOf(['data: {"text":"a"}\n\nevent: done\ndata: {}\n\n']),
    ).toList();

    expect(events.map((event) => event.event), [null, 'done']);
    expect(events.first.data, '{"text":"a"}');
  });

  test('remonta um evento quebrado no meio de um caractere UTF-8', () async {
    final bytes = utf8.encode('data: {"text":"ação"}\r\n\r\n');
    final split = bytes.indexOf(0xC3) + 1;
    final events = await decodeSse(
      Stream.fromIterable([bytes.sublist(0, split), bytes.sublist(split)]),
    ).toList();

    expect(events.single.data, '{"text":"ação"}');
  });

  test('ignora comentários de keep-alive', () async {
    final events = await decodeSse(_bytesOf([': ping\n\ndata: x\n\n']))
        .toList();

    expect(events.single.data, 'x');
  });
}
