import 'dart:async';
import 'dart:convert';
import 'dart:io';

class GeminiProxyTestServer {
  GeminiProxyTestServer._(this._server);

  final HttpServer _server;
  int statusCode = HttpStatus.ok;
  String body = '';
  final List<String> prompts = [];

  static Future<GeminiProxyTestServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = GeminiProxyTestServer._(server);
    server.listen((request) => unawaited(fake._handle(request)));
    return fake;
  }

  Uri get baseUrl => Uri.parse('http://127.0.0.1:${_server.port}');

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final json = jsonDecode(await utf8.decodeStream(request));
    if (json case {'prompt': final String prompt}) prompts.add(prompt);
    request.response
      ..statusCode = statusCode
      ..headers.contentType = statusCode == HttpStatus.ok
          ? ContentType('text', 'event-stream', charset: 'utf-8')
          : ContentType.json
      ..write(body);
    await request.response.close();
  }
}
