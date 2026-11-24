import 'dart:convert';

import 'package:gemini_proxy/gemini_proxy.dart';
import 'package:test/test.dart';

Stream<List<int>> _bytesOf(List<String> parts) =>
    Stream.fromIterable(parts.map(utf8.encode));

void main() {
  group('decodeSse', () {
    test('separa eventos por linha em branco e junta linhas de data', () async {
      final events = await decodeSse(
        _bytesOf(['data: um\ndata: dois\n\nevent: fim\ndata: {}\n\n']),
      ).toList();

      expect(events, hasLength(2));
      expect(events.first.event, isNull);
      expect(events.first.data, 'um\ndois');
      expect(events.last.event, 'fim');
      expect(events.last.data, '{}');
    });

    test(
      'aceita CRLF, comentários e eventos quebrados entre pacotes',
      () async {
        final events = await decodeSse(
          _bytesOf([': ping\r\nda', 'ta: {"text":"o', 'lá"}\r\n\r\n']),
        ).toList();

        expect(events.single.data, '{"text":"olá"}');
      },
    );

    test('entrega o último evento mesmo sem linha em branco final', () async {
      final events = await decodeSse(_bytesOf(['data: último'])).toList();

      expect(events.single.data, 'último');
    });
  });

  test('encodeSse gera um evento que decodeSse lê de volta', () async {
    final encoded = encodeSse(event: 'grounding', data: 'linha 1\nlinha 2');
    final events = await decodeSse(_bytesOf([encoded])).toList();

    expect(events.single.event, 'grounding');
    expect(events.single.data, 'linha 1\nlinha 2');
  });
}
