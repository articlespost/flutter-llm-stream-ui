import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:gemini_proxy/src/proxy_config.dart';
import 'package:gemini_proxy/src/sse.dart';

class GeminiApiException implements Exception {
  const GeminiApiException({
    required this.statusCode,
    required this.status,
    required this.message,
  });

  final int statusCode;
  final String status;
  final String message;

  @override
  String toString() => 'GeminiApiException($statusCode $status): $message';
}

class GeminiUnavailableException implements Exception {
  const GeminiUnavailableException(this.cause);

  final Object cause;

  @override
  String toString() => 'GeminiUnavailableException: $cause';
}

class GeminiClient {
  GeminiClient(this._config, {HttpClient? httpClient, math.Random? random})
    : _http = httpClient ?? HttpClient(),
      _random = random ?? math.Random() {
    _http.connectionTimeout = _config.connectionTimeout;
  }

  static const String systemInstruction =
      'Responda em português do Brasil, usando Markdown. Seja objetivo e, '
      'quando usar a busca, baseie a resposta nas fontes encontradas.';

  static const Set<int> _retryableStatusCodes = {408, 429, 500, 502, 503, 504};
  static const Duration _maxRetryDelay = Duration(seconds: 10);
  static const int _maxErrorBodyBytes = 8 * 1024;

  final ProxyConfig _config;
  final HttpClient _http;
  final math.Random _random;

  Uri get endpoint => Uri.parse(
    '${_config.apiBaseUrl}/v1beta/models/${_config.model}:streamGenerateContent',
  ).replace(queryParameters: const {'alt': 'sse'});

  Map<String, Object?> requestBody(String prompt) => {
    'systemInstruction': {
      'parts': [
        {'text': systemInstruction},
      ],
    },
    'contents': [
      {
        'role': 'user',
        'parts': [
          {'text': prompt},
        ],
      },
    ],
    if (_config.useGoogleSearch)
      'tools': [
        {'googleSearch': <String, Object?>{}},
      ],
  };

  Stream<String> streamGenerate(String prompt) async* {
    final response = await _openWithRetry(prompt);
    await for (final event in decodeSse(
      response.timeout(_config.idleTimeout),
    )) {
      yield event.data;
    }
  }

  void close() => _http.close(force: true);

  Future<HttpClientResponse> _openWithRetry(String prompt) async {
    final body = utf8.encode(jsonEncode(requestBody(prompt)));
    for (var attempt = 0; ; attempt++) {
      Duration? retryAfter;
      try {
        final request = await _http.postUrl(endpoint);
        request.headers
          ..contentType = ContentType.json
          ..set('x-goog-api-key', _config.apiKey);
        request.add(body);
        final response = await request.close().timeout(
          _config.connectionTimeout,
        );
        if (response.statusCode == HttpStatus.ok) return response;

        retryAfter = _retryAfterOf(response);
        final error = await _readError(response);
        if (!_retryableStatusCodes.contains(error.statusCode) ||
            attempt >= _config.maxRetries) {
          throw error;
        }
      } on IOException catch (error) {
        if (attempt >= _config.maxRetries) {
          throw GeminiUnavailableException(error);
        }
      } on TimeoutException catch (error) {
        if (attempt >= _config.maxRetries) {
          throw GeminiUnavailableException(error);
        }
      }
      await Future<void>.delayed(retryAfter ?? _backoff(attempt));
    }
  }

  Duration _backoff(int attempt) {
    final base = _config.retryBaseDelay.inMilliseconds * math.pow(2, attempt);
    final jitter = _random.nextDouble() * _config.retryBaseDelay.inMilliseconds;
    return Duration(milliseconds: (base + jitter).round());
  }

  Duration? _retryAfterOf(HttpClientResponse response) {
    final seconds = int.tryParse(
      response.headers.value(HttpHeaders.retryAfterHeader) ?? '',
    );
    if (seconds == null || seconds < 0) return null;
    final delay = Duration(seconds: seconds);
    return delay > _maxRetryDelay ? _maxRetryDelay : delay;
  }

  Future<GeminiApiException> _readError(HttpClientResponse response) async {
    final bytes = <int>[];
    try {
      await for (final chunk in response.timeout(_config.connectionTimeout)) {
        bytes.addAll(chunk);
        if (bytes.length > _maxErrorBodyBytes) break;
      }
    } on Object {
      bytes.clear();
    }
    var status = 'UNKNOWN';
    var message = 'HTTP ${response.statusCode}';
    try {
      final json = jsonDecode(utf8.decode(bytes, allowMalformed: true));
      if (json case {'error': final Map<String, Object?> error}) {
        if (error['status'] case final String value) status = value;
        if (error['message'] case final String value) message = value;
      }
    } on FormatException {
      status = 'UNKNOWN';
    }
    return GeminiApiException(
      statusCode: response.statusCode,
      status: status,
      message: message,
    );
  }
}
