import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gemini_proxy/src/gemini_client.dart';
import 'package:gemini_proxy/src/gemini_stream_parser.dart';
import 'package:gemini_proxy/src/proxy_config.dart';
import 'package:gemini_proxy/src/rate_limiter.dart';
import 'package:gemini_proxy/src/sse.dart';

typedef ProxyLogger = void Function(String message);

class ProxyServer {
  ProxyServer(
    this._config, {
    GeminiClient? client,
    RateLimiter? rateLimiter,
    ProxyLogger? log,
  }) : _client = client ?? GeminiClient(_config),
       _rateLimiter =
           rateLimiter ??
           RateLimiter(
             maxRequests: _config.requestsPerMinute,
             window: const Duration(minutes: 1),
           ),
       _log = log ?? _silent;

  static const String streamPath = '/v1/completions:stream';
  static const String healthPath = '/health';

  final ProxyConfig _config;
  final GeminiClient _client;
  final RateLimiter _rateLimiter;
  final ProxyLogger _log;
  HttpServer? _server;
  int _activeStreams = 0;

  Future<int> start() async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      _config.port,
    );
    _server = server;
    server.listen((request) => unawaited(_handle(request)));
    return server.port;
  }

  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
    _client.close();
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      switch (request.uri.path) {
        case healthPath when request.method == 'GET':
          await _json(request.response, HttpStatus.ok, {
            'status': 'ok',
            'model': _config.model,
            'googleSearch': _config.useGoogleSearch,
          });
        case streamPath when request.method == 'POST':
          await _handleStream(request);
        case healthPath || streamPath:
          await _error(
            request.response,
            HttpStatus.methodNotAllowed,
            'method_not_allowed',
          );
        default:
          await _error(request.response, HttpStatus.notFound, 'not_found');
      }
    } on Object catch (error) {
      _log(
        '${request.method} ${request.uri.path} failed: ${error.runtimeType}',
      );
      try {
        await _error(
          request.response,
          HttpStatus.internalServerError,
          'internal_error',
        );
      } on Object {
        return;
      }
    }
  }

  Future<void> _handleStream(HttpRequest request) async {
    if (request.headers.contentType?.mimeType != ContentType.json.mimeType) {
      return _error(
        request.response,
        HttpStatus.unsupportedMediaType,
        'invalid_content_type',
      );
    }
    final body = await _readBody(request);
    if (body == null) {
      return _error(
        request.response,
        HttpStatus.requestEntityTooLarge,
        'payload_too_large',
      );
    }
    final prompt = _promptOf(body);
    if (prompt == null) {
      return _error(request.response, HttpStatus.badRequest, 'invalid_prompt');
    }
    if (_activeStreams >= _config.maxConcurrentStreams) {
      return _error(request.response, HttpStatus.tooManyRequests, 'busy');
    }
    if (!_rateLimiter.tryAcquire()) {
      return _error(
        request.response,
        HttpStatus.tooManyRequests,
        'rate_limited',
      );
    }
    _activeStreams++;
    try {
      await _stream(request.response, prompt);
    } finally {
      _activeStreams--;
    }
  }

  Future<void> _stream(HttpResponse response, String prompt) async {
    response
      ..statusCode = HttpStatus.ok
      ..persistentConnection = false;
    response.headers
      ..contentType = ContentType('text', 'event-stream', charset: 'utf-8')
      ..chunkedTransferEncoding = false
      ..set(HttpHeaders.cacheControlHeader, 'no-cache');
    final socket = await response.detachSocket();

    final clientGone = Completer<void>();
    void markClientGone() {
      if (!clientGone.isCompleted) clientGone.complete();
    }

    final watcher = socket.listen(
      (_) {},
      onDone: markClientGone,
      onError: (Object _) => markClientGone(),
      cancelOnError: true,
    );

    final stopwatch = Stopwatch()..start();
    final parser = GeminiStreamParser();
    var outcome = 'ok';
    try {
      final upstream = _untilClientGone(
        _client.streamGenerate(prompt),
        clientGone.future,
      );
      await for (final data in upstream) {
        for (final event in parser.parse(data)) {
          switch (event) {
            case GeminiText(:final text):
              if (!await _send(socket, data: jsonEncode({'text': text}))) {
                outcome = 'client_closed';
                return;
              }
            case GeminiBlocked(:final reason):
              outcome = 'blocked $reason';
              await _send(
                socket,
                event: 'error',
                data: jsonEncode({'code': 'blocked', 'detail': reason}),
              );
              return;
          }
        }
      }
      if (clientGone.isCompleted) {
        outcome = 'client_closed';
        return;
      }
      if (!parser.grounding.isEmpty) {
        await _send(
          socket,
          event: 'grounding',
          data: jsonEncode(parser.grounding.toJson()),
        );
      }
      await _send(socket, event: 'done', data: '{}');
    } on GeminiApiException catch (error) {
      outcome = 'upstream ${error.statusCode} ${error.status}';
      await _send(
        socket,
        event: 'error',
        data: jsonEncode({
          'code': _codeFor(error.statusCode),
          'status': error.statusCode,
          'detail': error.message,
        }),
      );
    } on Object catch (error) {
      outcome = 'unavailable ${error.runtimeType}';
      await _send(
        socket,
        event: 'error',
        data: jsonEncode({'code': 'unavailable'}),
      );
    } finally {
      await watcher.cancel();
      try {
        await socket.close();
      } on IOException {
        outcome = '$outcome (socket_error)';
      }
      socket.destroy();
      _log(
        'POST $streamPath ${_config.model} '
        'search=${_config.useGoogleSearch} $outcome '
        '${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  static Stream<T> _untilClientGone<T>(
    Stream<T> source,
    Future<void> clientGone,
  ) {
    StreamSubscription<T>? subscription;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        subscription = source.listen(
          (data) {
            if (!controller.isClosed) controller.add(data);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) controller.addError(error, stackTrace);
          },
          onDone: controller.close,
        );
        unawaited(
          clientGone.then((_) {
            unawaited(subscription?.cancel());
            unawaited(controller.close());
          }),
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  static String _codeFor(int statusCode) => switch (statusCode) {
    HttpStatus.badRequest => 'invalid_request',
    HttpStatus.unauthorized || HttpStatus.forbidden => 'permission_denied',
    HttpStatus.notFound => 'model_not_found',
    HttpStatus.tooManyRequests => 'quota_exceeded',
    _ => 'upstream_error',
  };

  Future<bool> _send(
    Socket socket, {
    String? event,
    required String data,
  }) async {
    try {
      socket.add(utf8.encode(encodeSse(event: event, data: data)));
      await socket.flush();
      return true;
    } on IOException {
      return false;
    } on StateError {
      return false;
    }
  }

  Future<String?> _readBody(HttpRequest request) async {
    final builder = BytesBuilder(copy: false);
    var isTooLarge = request.contentLength > _config.maxBodyBytes;
    await for (final chunk in request.timeout(_config.connectionTimeout)) {
      if (isTooLarge) continue;
      builder.add(chunk);
      isTooLarge = builder.length > _config.maxBodyBytes;
    }
    if (isTooLarge) return null;
    return utf8.decode(builder.takeBytes(), allowMalformed: true);
  }

  String? _promptOf(String body) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (json case {'prompt': final String prompt}) {
      final trimmed = prompt.trim();
      if (trimmed.isNotEmpty && trimmed.length <= _config.maxPromptLength) {
        return trimmed;
      }
    }
    return null;
  }

  Future<void> _error(HttpResponse response, int statusCode, String code) =>
      _json(response, statusCode, {'code': code});

  Future<void> _json(
    HttpResponse response,
    int statusCode,
    Map<String, Object?> body,
  ) async {
    response
      ..statusCode = statusCode
      ..persistentConnection = statusCode < HttpStatus.badRequest
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await response.close();
  }

  static void _silent(String message) {}
}
