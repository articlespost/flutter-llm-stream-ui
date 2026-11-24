import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gemini_proxy/gemini_proxy.dart';
import 'package:test/test.dart';

const String _apiKey = 'chave-sintetica-de-teste';

class _FakeGemini {
  _FakeGemini(this._server);

  final HttpServer _server;
  final List<int> statusQueue = [];
  final List<Map<String, Object?>> bodies = [];
  final List<String?> apiKeys = [];
  final List<String> paths = [];
  List<String> chunks = [];
  Duration chunkDelay = Duration.zero;
  bool upstreamClosedEarly = false;
  int requestCount = 0;

  static Future<_FakeGemini> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = _FakeGemini(server);
    server.listen((request) => unawaited(fake._handle(request)));
    return fake;
  }

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    requestCount++;
    paths.add(request.uri.toString());
    apiKeys.add(request.headers.value('x-goog-api-key'));
    final body = await utf8.decodeStream(request);
    bodies.add(jsonDecode(body) as Map<String, Object?>);

    final status = statusQueue.isEmpty ? 200 : statusQueue.removeAt(0);
    final response = request.response..statusCode = status;
    if (status != 200) {
      response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'error': {
              'code': status,
              'message': 'falha simulada',
              'status': 'SIMULATED',
            },
          }),
        );
      await response.close();
      return;
    }
    response
      ..persistentConnection = false
      ..headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      )
      ..headers.chunkedTransferEncoding = false;
    final socket = await response.detachSocket();
    var isProxyGone = false;
    final watcher = socket.listen(
      (_) {},
      onDone: () => isProxyGone = true,
      onError: (Object _) => isProxyGone = true,
    );
    for (final chunk in chunks) {
      await Future<void>.delayed(chunkDelay);
      if (isProxyGone) {
        upstreamClosedEarly = true;
        break;
      }
      socket.add(utf8.encode('data: $chunk\r\n\r\n'));
      await socket.flush();
    }
    await watcher.cancel();
    socket.destroy();
  }
}

String _textChunk(String text) => jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': text},
        ],
      },
    },
  ],
});

String _groundingChunk() => jsonEncode({
  'candidates': [
    {
      'content': {'parts': <Object?>[]},
      'finishReason': 'STOP',
      'groundingMetadata': {
        'webSearchQueries': ['o que é flutter'],
        'searchEntryPoint': {'renderedContent': '<div>sugestões</div>'},
        'groundingChunks': [
          {
            'web': {'uri': 'https://fonte.example', 'title': 'fonte.example'},
          },
        ],
      },
    },
  ],
});

void main() {
  late _FakeGemini gemini;
  late ProxyServer proxy;
  late HttpClient client;
  late Uri baseUri;
  final logs = <String>[];

  Future<void> startProxy({
    int requestsPerMinute = 10,
    int maxBodyBytes = 16 * 1024,
    bool useGoogleSearch = false,
  }) async {
    final config = ProxyConfig(
      apiKey: _apiKey,
      port: 0,
      useGoogleSearch: useGoogleSearch,
      apiBaseUrl: gemini.baseUrl,
      requestsPerMinute: requestsPerMinute,
      maxBodyBytes: maxBodyBytes,
      retryBaseDelay: const Duration(milliseconds: 1),
    );
    proxy = ProxyServer(config, log: logs.add);
    final port = await proxy.start();
    baseUri = Uri.parse('http://127.0.0.1:$port');
  }

  Future<HttpClientResponse> post(
    Object body, {
    ContentType? contentType,
  }) async {
    final request = await client.postUrl(
      baseUri.resolve(ProxyServer.streamPath),
    );
    request.headers.contentType = contentType ?? ContentType.json;
    request.write(body is String ? body : jsonEncode(body));
    return request.close();
  }

  Future<List<SseEvent>> events(HttpClientResponse response) =>
      decodeSse(response).toList();

  Future<void> untilLogged() async {
    for (var attempt = 0; attempt < 400 && logs.isEmpty; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  setUp(() async {
    logs.clear();
    gemini = await _FakeGemini.start();
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await proxy.close();
    await gemini.close();
  });

  test('repassa o texto em SSE, depois as fontes e o fim', () async {
    gemini.chunks = [
      _textChunk('Flutter é '),
      _textChunk('um SDK.'),
      _groundingChunk(),
    ];
    await startProxy();

    final response = await post({'prompt': '  O que é Flutter?  '});
    final received = await events(response);

    expect(response.statusCode, 200);
    expect(response.headers.contentType?.mimeType, 'text/event-stream');
    expect(received.map((event) => event.event), [
      null,
      null,
      'grounding',
      'done',
    ]);
    expect(
      received
          .where((event) => event.event == null)
          .map(
            (event) => (jsonDecode(event.data) as Map<String, Object?>)['text'],
          ),
      ['Flutter é ', 'um SDK.'],
    );
    expect(jsonDecode(received[2].data), {
      'sources': [
        {'uri': 'https://fonte.example', 'title': 'fonte.example'},
      ],
      'searchQueries': ['o que é flutter'],
      'renderedContent': '<div>sugestões</div>',
    });
  });

  test(
    'envia a chave só no cabeçalho, com o modelo e a busca ativada',
    () async {
      gemini.chunks = [_textChunk('ok')];
      await startProxy(useGoogleSearch: true);

      await events(await post({'prompt': 'Oi'}));
      await untilLogged();

      expect(gemini.apiKeys.single, _apiKey);
      expect(gemini.paths.single, contains(':streamGenerateContent?alt=sse'));
      expect(gemini.paths.single, contains(ProxyConfig.defaultModel));
      expect(gemini.paths.single, isNot(contains(_apiKey)));
      expect(gemini.bodies.single['tools'], [
        {'googleSearch': <String, Object?>{}},
      ]);
      expect(gemini.bodies.single['contents'], [
        {
          'role': 'user',
          'parts': [
            {'text': 'Oi'},
          ],
        },
      ]);
      expect(logs.single, isNot(contains('Oi')));
      expect(logs.single, isNot(contains(_apiKey)));
    },
  );

  test('com a busca desligada, não envia a ferramenta de busca', () async {
    gemini.chunks = [_textChunk('ok')];
    await startProxy();

    await events(await post({'prompt': 'Oi'}));

    expect(gemini.paths.single, contains(ProxyConfig.defaultModel));
    expect(gemini.bodies.single.containsKey('tools'), isFalse);
  });

  test('tenta de novo com backoff quando o Gemini está indisponível', () async {
    gemini
      ..statusQueue.addAll([503, 429])
      ..chunks = [_textChunk('voltou')];
    await startProxy();

    final received = await events(await post({'prompt': 'Oi'}));

    expect(gemini.requestCount, 3);
    expect(received.first.data, '{"text":"voltou"}');
    expect(received.last.event, 'done');
  });

  test('não repete erros definitivos e devolve um código de erro', () async {
    gemini.statusQueue.add(403);
    await startProxy();

    final received = await events(await post({'prompt': 'Oi'}));

    await untilLogged();

    expect(gemini.requestCount, 1);
    expect(received.single.event, 'error');
    expect(jsonDecode(received.single.data), {
      'code': 'permission_denied',
      'status': 403,
      'detail': 'falha simulada',
    });
    expect(logs.single, contains('upstream 403 SIMULATED: falha simulada'));
    expect(logs.single, isNot(contains(_apiKey)));
  });

  test('valida o pedido antes de chamar o Gemini', () async {
    await startProxy();

    Future<int> statusOf(Future<HttpClientResponse> pending) async {
      final response = await pending;
      await response.drain<void>();
      return response.statusCode;
    }

    Future<HttpClientResponse> get(String path) async =>
        (await client.getUrl(baseUri.resolve(path))).close();

    expect(await statusOf(post({'prompt': '   '})), 400);
    expect(await statusOf(post({'prompt': 'a' * 2001})), 400);
    expect(await statusOf(post('prompt', contentType: ContentType.text)), 415);
    expect(await statusOf(get(ProxyServer.streamPath)), 405);
    expect(await statusOf(get('/x')), 404);
    expect(gemini.requestCount, 0);
  });

  test('cancela a chamada ao Gemini quando o app desiste', () async {
    gemini
      ..chunkDelay = const Duration(milliseconds: 20)
      ..chunks = List.generate(200, (index) => _textChunk('pedaço $index '));
    await startProxy();

    final response = await post({'prompt': 'Resposta longa'});
    final first = await decodeSse(response).first;
    client.close(force: true);
    await untilLogged();

    expect(first.data, contains('pedaço 0'));
    expect(logs.single, contains('client_closed'));
    for (
      var attempt = 0;
      attempt < 100 && !gemini.upstreamClosedEarly;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(gemini.upstreamClosedEarly, isTrue);
  });

  test('recusa corpos maiores que o limite', () async {
    await startProxy(maxBodyBytes: 64);

    final response = await post({'prompt': 'a' * 100});
    await response.drain<void>();

    expect(response.statusCode, 413);
    expect(gemini.requestCount, 0);
  });

  test('limita a taxa de pedidos por minuto', () async {
    gemini.chunks = [_textChunk('ok')];
    await startProxy(requestsPerMinute: 1);

    final first = await post({'prompt': 'Oi'});
    await first.drain<void>();
    final second = await post({'prompt': 'Oi de novo'});
    final body = await utf8.decodeStream(second);

    expect(first.statusCode, 200);
    expect(second.statusCode, 429);
    expect(jsonDecode(body), {'code': 'rate_limited'});
    expect(gemini.requestCount, 1);
  });

  test('responde ao health check sem expor a chave', () async {
    await startProxy();

    final response = await (await client.getUrl(
      baseUri.resolve(ProxyServer.healthPath),
    )).close();
    final body = await utf8.decodeStream(response);

    expect(response.statusCode, 200);
    expect(jsonDecode(body), {
      'status': 'ok',
      'model': ProxyConfig.defaultModel,
      'googleSearch': false,
    });
    expect(body, isNot(contains(_apiKey)));
  });
}
