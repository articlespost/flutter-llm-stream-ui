import 'dart:convert';

import 'package:gemini_proxy/gemini_proxy.dart';
import 'package:test/test.dart';

String _chunk({
  List<Map<String, Object?>> parts = const [],
  Map<String, Object?>? groundingMetadata,
  String? finishReason,
}) => jsonEncode({
  'candidates': [
    {
      'content': {'role': 'model', 'parts': parts},
      'groundingMetadata': ?groundingMetadata,
      'finishReason': ?finishReason,
    },
  ],
});

void main() {
  test('extrai o texto das partes e ignora partes de raciocínio', () {
    final parser = GeminiStreamParser();

    final events = parser.parse(
      _chunk(
        parts: [
          {'text': 'pensando', 'thought': true},
          {'text': 'Olá'},
          {'text': ', mundo'},
        ],
      ),
    );

    expect(events.map((event) => (event as GeminiText).text), [
      'Olá',
      ', mundo',
    ]);
  });

  test('acumula as fontes da busca entre pedaços, sem repetir', () {
    final parser = GeminiStreamParser()
      ..parse(
        _chunk(
          groundingMetadata: {
            'webSearchQueries': ['flutter 2026'],
            'groundingChunks': [
              {
                'web': {'uri': 'https://a.example', 'title': 'a.example'},
              },
            ],
          },
        ),
      )
      ..parse(
        _chunk(
          finishReason: 'STOP',
          groundingMetadata: {
            'webSearchQueries': ['flutter 2026'],
            'searchEntryPoint': {'renderedContent': '<div>chips</div>'},
            'groundingChunks': [
              {
                'web': {'uri': 'https://a.example', 'title': 'a.example'},
              },
              {
                'web': {'uri': 'https://b.example'},
              },
            ],
          },
        ),
      );

    expect(parser.grounding.toJson(), {
      'sources': [
        {'uri': 'https://a.example', 'title': 'a.example'},
        {'uri': 'https://b.example', 'title': 'https://b.example'},
      ],
      'searchQueries': ['flutter 2026'],
      'renderedContent': '<div>chips</div>',
    });
  });

  test('sinaliza bloqueio do prompt e de segurança na resposta', () {
    final parser = GeminiStreamParser();

    final blockedPrompt = parser.parse(
      jsonEncode({
        'promptFeedback': {'blockReason': 'SAFETY'},
      }),
    );
    final blockedAnswer = parser.parse(_chunk(finishReason: 'SAFETY'));

    expect((blockedPrompt.single as GeminiBlocked).reason, 'SAFETY');
    expect((blockedAnswer.single as GeminiBlocked).reason, 'SAFETY');
    expect(parser.grounding.isEmpty, isTrue);
  });

  test('ignora pedaços que não são JSON', () {
    expect(GeminiStreamParser().parse('[DONE]'), isEmpty);
  });
}
