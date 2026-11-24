import 'dart:io';

import 'package:gemini_proxy/gemini_proxy.dart';

Future<void> main() async {
  final ProxyConfig config;
  try {
    config = ProxyConfig.fromEnvironment(Platform.environment);
  } on ProxyConfigException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
    return;
  }

  final server = ProxyServer(config, log: stdout.writeln);
  final port = await server.start();
  final search = config.useGoogleSearch ? 'ativada' : 'desativada';
  stdout
    ..writeln('Proxy do Gemini em http://127.0.0.1:$port')
    ..writeln('Modelo: ${config.model} | Busca no Google: $search')
    ..writeln('Ctrl+C para encerrar.');

  await ProcessSignal.sigint.watch().first;
  await server.close();
  stdout.writeln('Proxy encerrado.');
}
