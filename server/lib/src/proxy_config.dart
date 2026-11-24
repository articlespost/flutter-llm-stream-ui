class ProxyConfigException implements Exception {
  const ProxyConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProxyConfig {
  const ProxyConfig({
    required this.apiKey,
    this.model = defaultModel,
    this.useGoogleSearch = false,
    this.port = defaultPort,
    this.apiBaseUrl = defaultApiBaseUrl,
    this.maxPromptLength = 2000,
    this.maxBodyBytes = 16 * 1024,
    this.requestsPerMinute = 10,
    this.maxConcurrentStreams = 2,
    this.connectionTimeout = const Duration(seconds: 10),
    this.idleTimeout = const Duration(seconds: 30),
    this.maxRetries = 2,
    this.retryBaseDelay = const Duration(milliseconds: 500),
  });

  factory ProxyConfig.fromEnvironment(Map<String, String> environment) {
    final apiKey = environment['GEMINI_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw const ProxyConfigException(
        'Defina a variável de ambiente GEMINI_API_KEY antes de iniciar o proxy.',
      );
    }
    final model = environment['GEMINI_MODEL']?.trim() ?? '';
    if (model.isNotEmpty && !modelPattern.hasMatch(model)) {
      throw ProxyConfigException('GEMINI_MODEL inválido: $model');
    }
    return ProxyConfig(
      apiKey: apiKey,
      model: model.isEmpty ? defaultModel : model,
      useGoogleSearch: _parseBool(
        environment['GEMINI_GOOGLE_SEARCH'],
        name: 'GEMINI_GOOGLE_SEARCH',
      ),
      port: _parsePort(environment['PROXY_PORT']),
    );
  }

  static const String defaultModel = 'gemini-3.5-flash-lite';
  static const int defaultPort = 8787;
  static const String defaultApiBaseUrl =
      'https://generativelanguage.googleapis.com';

  static final RegExp modelPattern = RegExp(r'^[a-z0-9][a-z0-9.\-]*$');

  final String apiKey;
  final String model;
  final bool useGoogleSearch;
  final int port;
  final String apiBaseUrl;
  final int maxPromptLength;
  final int maxBodyBytes;
  final int requestsPerMinute;
  final int maxConcurrentStreams;
  final Duration connectionTimeout;
  final Duration idleTimeout;
  final int maxRetries;
  final Duration retryBaseDelay;

  static bool _parseBool(String? value, {required String name}) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized.isEmpty || normalized == 'false' || normalized == '0') {
      return false;
    }
    throw ProxyConfigException('$name deve ser true ou false.');
  }

  static int _parsePort(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return defaultPort;
    final port = int.tryParse(normalized);
    if (port == null || port < 1024 || port > 65535) {
      throw const ProxyConfigException(
        'PROXY_PORT deve ser um número entre 1024 e 65535.',
      );
    }
    return port;
  }
}
