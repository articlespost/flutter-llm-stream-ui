import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:llm_stream_ui/src/core/network/sse_decoder.dart';

class HttpStatusException implements Exception {
  const HttpStatusException(this.statusCode, {this.code});

  final int statusCode;
  final String? code;

  @override
  String toString() => 'HttpStatusException($statusCode, $code)';
}

class StreamingHttpClient {
  StreamingHttpClient({
    HttpClient? client,
    this.connectionTimeout = const Duration(seconds: 10),
    this.idleTimeout = const Duration(seconds: 45),
  }) : _client = client ?? HttpClient() {
    _client.connectionTimeout = connectionTimeout;
  }

  static const int _maxErrorBodyBytes = 4 * 1024;

  final HttpClient _client;
  final Duration connectionTimeout;
  final Duration idleTimeout;

  Stream<SseEvent> postForEvents(Uri uri, Map<String, Object?> body) async* {
    final request = await _client.postUrl(uri);
    request.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.acceptHeader, 'text/event-stream');
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close().timeout(connectionTimeout);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpStatusException(
        response.statusCode,
        code: await _errorCodeOf(response),
      );
    }
    yield* decodeSse(response.timeout(idleTimeout));
  }

  void close() => _client.close(force: true);

  Future<String?> _errorCodeOf(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response.timeout(connectionTimeout)) {
      bytes.addAll(chunk);
      if (bytes.length > _maxErrorBodyBytes) break;
    }
    try {
      if (jsonDecode(utf8.decode(bytes, allowMalformed: true)) case {
        'code': final String code,
      }) {
        return code;
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}
