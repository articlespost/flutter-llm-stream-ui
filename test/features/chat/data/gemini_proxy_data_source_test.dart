import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:llm_stream_ui/src/core/network/streaming_http_client.dart';
import 'package:llm_stream_ui/src/features/chat/data/datasource/gemini_proxy_data_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/datasource/llm_stream_data_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_event.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_failure.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/response_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/search_grounding.dart';
import 'package:llm_stream_ui/src/features/chat/data/models/completion_event_model.dart';
import 'package:llm_stream_ui/src/features/chat/data/models/completion_request_model.dart';
import 'package:llm_stream_ui/src/features/chat/data/models/remote_completion_exception.dart';
import 'package:llm_stream_ui/src/features/chat/data/repositories/chat_repository_impl.dart';

import 'gemini_proxy_test_server.dart';

const String _groundedStream =
    'data: {"text":"Flutter é "}\n\n'
    'data: {"text":"um SDK."}\n\n'
    'event: grounding\n'
    'data: {"sources":[{"title":"flutter.dev","uri":"https://flutter.dev"},'
    '{"title":"inseguro","uri":"http://inseguro.example"}],'
    '"searchQueries":["o que é flutter"],"renderedContent":"<div></div>"}\n\n'
    'event: done\n'
    'data: {}\n\n';

void main() {
  late GeminiProxyTestServer server;
  late StreamingHttpClient client;
  late GeminiProxyDataSource dataSource;

  setUp(() async {
    server = await GeminiProxyTestServer.start();
    client = StreamingHttpClient(
      connectionTimeout: const Duration(seconds: 2),
      idleTimeout: const Duration(seconds: 2),
    );
    dataSource = GeminiProxyDataSource(client, baseUrl: server.baseUrl);
  });

  tearDown(() async {
    client.close();
    await server.close();
  });

  Future<List<CompletionEventModel>> collect() => dataSource
      .streamCompletion(
        const CompletionRequestModel(prompt: 'O que é Flutter?'),
      )
      .toList();

  group('GeminiProxyDataSource', () {
    test('converte o SSE do proxy em texto e fontes da busca', () async {
      server.body = _groundedStream;

      final events = await collect();

      expect(server.prompts, ['O que é Flutter?']);
      expect(
        events.whereType<TextDeltaModel>().map((event) => event.text).join(),
        'Flutter é um SDK.',
      );
      final grounding = events.whereType<GroundingModel>().single;
      expect(grounding.sources.map((source) => source.uri.toString()), [
        'https://flutter.dev',
      ]);
      expect(grounding.searchQueries, ['o que é flutter']);
      expect(grounding.renderedContent, '<div></div>');
    });

    test('lança o código do evento de erro do proxy', () async {
      server.body = 'event: error\ndata: {"code":"quota_exceeded"}\n\n';

      await expectLater(
        collect(),
        throwsA(
          isA<RemoteCompletionException>().having(
            (error) => error.code,
            'code',
            'quota_exceeded',
          ),
        ),
      );
    });

    test('trata o fim sem o evento done como resposta interrompida', () async {
      server.body = 'data: {"text":"meia resp"}\n\n';

      await expectLater(
        collect(),
        throwsA(
          isA<RemoteCompletionException>().having(
            (error) => error.code,
            'code',
            RemoteCompletionException.interrupted,
          ),
        ),
      );
    });

    test('lança o status e o código quando o proxy recusa o pedido', () async {
      server
        ..statusCode = HttpStatus.tooManyRequests
        ..body = '{"code":"rate_limited"}';

      await expectLater(
        collect(),
        throwsA(
          isA<HttpStatusException>()
              .having((error) => error.statusCode, 'statusCode', 429)
              .having((error) => error.code, 'code', 'rate_limited'),
        ),
      );
    });
  });

  group('ChatRepositoryImpl com o Gemini', () {
    ChatRepositoryImpl repository() => ChatRepositoryImpl(
      const LlmStreamDataSource(),
      geminiDataSource: dataSource,
    );

    test('entrega entidades de texto e de busca', () async {
      server.body = _groundedStream;

      final events = await repository()
          .streamCompletion('O que é Flutter?', source: ResponseSource.gemini)
          .toList();

      expect(events.whereType<TextDelta>(), hasLength(2));
      expect(
        events.whereType<GroundingReceived>().single.grounding,
        SearchGrounding(
          sources: [
            GroundingSource(
              title: 'flutter.dev',
              uri: Uri.parse('https://flutter.dev'),
            ),
          ],
          searchQueries: ['o que é flutter'],
          renderedContent: '<div></div>',
        ),
      );
    });

    test('traduz os erros do proxy em falhas do domínio', () async {
      final cases = {
        'event: error\ndata: {"code":"quota_exceeded"}\n\n':
            CompletionFailureReason.quotaExceeded,
        'event: error\ndata: {"code":"permission_denied"}\n\n':
            CompletionFailureReason.permissionDenied,
        'event: error\ndata: {"code":"model_not_found"}\n\n':
            CompletionFailureReason.modelNotFound,
        'event: error\ndata: {"code":"blocked"}\n\n':
            CompletionFailureReason.blocked,
        'event: error\ndata: {"code":"unavailable"}\n\n':
            CompletionFailureReason.sourceUnavailable,
        'data: {"text":"meia"}\n\n': CompletionFailureReason.interrupted,
      };
      for (final MapEntry(key: body, value: reason) in cases.entries) {
        server.body = body;
        await expectLater(
          repository()
              .streamCompletion('Oi', source: ResponseSource.gemini)
              .toList(),
          throwsA(CompletionFailure(reason)),
          reason: body,
        );
      }
    });

    test('proxy desligado vira fonte indisponível', () async {
      final port = server.baseUrl.port;
      await server.close();
      final offline = ChatRepositoryImpl(
        const LlmStreamDataSource(),
        geminiDataSource: GeminiProxyDataSource(
          StreamingHttpClient(
            connectionTimeout: const Duration(milliseconds: 500),
          ),
          baseUrl: Uri.parse('http://127.0.0.1:$port'),
        ),
      );

      await expectLater(
        offline.streamCompletion('Oi', source: ResponseSource.gemini).toList(),
        throwsA(
          const CompletionFailure(CompletionFailureReason.sourceUnavailable),
        ),
      );
    });

    test('sem proxy configurado, o Gemini fica indisponível', () async {
      const repository = ChatRepositoryImpl(LlmStreamDataSource());

      expect(repository.isAvailable(ResponseSource.gemini), isFalse);
      expect(repository.isAvailable(ResponseSource.simulated), isTrue);
      await expectLater(
        repository
            .streamCompletion('Oi', source: ResponseSource.gemini)
            .toList(),
        throwsA(
          const CompletionFailure(CompletionFailureReason.sourceUnavailable),
        ),
      );
    });
  });
}
