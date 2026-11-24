import 'dart:math' as math;

import 'package:llm_stream_ui/src/features/chat/data/models/completion_request_model.dart';

class LlmStreamDataSource {
  const LlmStreamDataSource({
    this.chunkInterval = const Duration(milliseconds: 8),
    this.seed = 42,
  });

  final Duration chunkInterval;
  final int seed;

  Stream<String> streamCompletion(CompletionRequestModel request) async* {
    final response = _responseFor(request.prompt);
    final random = math.Random(seed);
    var index = 0;
    while (index < response.length) {
      final end = math.min(index + 2 + random.nextInt(7), response.length);
      await Future<void>.delayed(chunkInterval);
      yield response.substring(index, end);
      index = end;
    }
  }

  static String _responseFor(String prompt) {
    final normalized = prompt.toLowerCase();
    if (normalized.contains('estresse') || normalized.contains('longa')) {
      return List.filled(
        3,
        '$_dartStreams\n\n$_kotlinFlow\n\n$_sseClient',
      ).join('\n\n---\n\n');
    }
    if (normalized.contains('kotlin') || normalized.contains('flow')) {
      return _kotlinFlow;
    }
    if (normalized.contains('python') || normalized.contains('sse')) {
      return _sseClient;
    }
    return _dartStreams;
  }

  static const String _dartStreams = r'''
# Streams em Dart, sem mistério

Um **Stream** entrega uma sequência de eventos assíncronos ao longo do tempo. É exatamente o formato de uma resposta de LLM em *streaming*: o texto chega em pedaços, e a interface precisa acompanhar sem travar.

## Consumindo um stream

```dart
final subscription = completion.listen(
  (chunk) => buffer.write(chunk),
  onError: (Object error) => debugPrint('falha: $error'),
  onDone: () => debugPrint('resposta completa'),
);
```

Três cuidados que valem para qualquer app:

1. Cancele a assinatura no `dispose`, senão o stream continua vivo.
2. Não chame `setState` a cada chunk: agrupe as atualizações por frame.
3. Reconstrua só o widget que mudou, não a tela inteira.

## StreamBuilder ou ValueNotifier?

| Abordagem | Quando usar | Custo por evento |
|---|---|---|
| `StreamBuilder` | Fluxo simples, uma área da tela | Rebuild do builder |
| `ValueNotifier` | Estado com regras e agrupamento | Rebuild só de quem escuta |
| `setState` na tela | Quase nunca em streaming | Rebuild da tela inteira |

> O custo de um frame é proporcional ao que você manda reconstruir, não ao tamanho do chunk.

Com isso, a resposta flui no ritmo da tela, mesmo com blocos de código longos.''';

  static const String _kotlinFlow = r'''
## Fluxos reativos no Kotlin

No Android nativo, o equivalente ao `Stream` é o **Flow**. A ideia é a mesma: produzir valores sob demanda e coletá-los em uma corrotina.

```kotlin
fun completion(prompt: String): Flow<String> = flow {
    for (token in model.generate(prompt)) {
        emit(token)
    }
}.flowOn(Dispatchers.Default)
```

- `flowOn` muda o contexto de **quem produz**, não de quem coleta.
- Na UI com Compose, colete com `collectAsStateWithLifecycle`.
  - Assim a coleta para quando a tela sai de cena.
- Use `conflate()` quando só o valor mais recente importa.

### Comparando com Dart

| Kotlin | Dart |
|:---|:---|
| `Flow<T>` | `Stream<T>` |
| `collect` | `listen` |
| `conflate()` | agrupamento por frame |

Nos dois mundos, ~~atualizar a UI a cada token~~ agrupar as atualizações é o que mantém a interface fluida. Veja a [documentação do Flow](https://kotlinlang.org/docs/flow.html) para os detalhes.''';

  static const String _sseClient = r'''
### Como o texto chega da API

Muitas APIs de LLM enviam a resposta como eventos SSE, cada um com um pedaço do texto:

```json
{"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": "Olá"}}
```

Um cliente mínimo em Python junta esses pedaços assim:

```python
def stream_text(events):
    parts = []
    for event in events:
        if event["type"] == "content_block_delta":
            parts.append(event["delta"]["text"])
            yield "".join(parts)
```

Repare no detalhe: devolver o texto **inteiro** a cada evento é o mesmo erro da UI ingênua. O custo cresce junto com a resposta, e quem paga é o frame.''';
}
