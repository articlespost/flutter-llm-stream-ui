import 'package:gemini_proxy/gemini_proxy.dart';
import 'package:test/test.dart';

void main() {
  group('ProxyConfig.fromEnvironment', () {
    test('exige a chave da API', () {
      expect(
        () => ProxyConfig.fromEnvironment(const {}),
        throwsA(isA<ProxyConfigException>()),
      );
    });

    test('por padrão usa o modelo gratuito, sem busca, na porta padrão', () {
      final config = ProxyConfig.fromEnvironment(const {
        'GEMINI_API_KEY': 'chave-sintetica',
      });

      expect(config.model, 'gemini-3.5-flash-lite');
      expect(config.useGoogleSearch, isFalse);
      expect(config.port, ProxyConfig.defaultPort);
    });

    test('lê modelo, busca e porta das variáveis', () {
      final config = ProxyConfig.fromEnvironment(const {
        'GEMINI_API_KEY': 'chave-sintetica',
        'GEMINI_MODEL': 'gemini-2.5-flash-lite',
        'GEMINI_GOOGLE_SEARCH': 'true',
        'PROXY_PORT': '9090',
      });

      expect(config.model, 'gemini-2.5-flash-lite');
      expect(config.useGoogleSearch, isTrue);
      expect(config.port, 9090);
    });

    test('rejeita valor inválido para a busca', () {
      expect(
        () => ProxyConfig.fromEnvironment(const {
          'GEMINI_API_KEY': 'chave-sintetica',
          'GEMINI_GOOGLE_SEARCH': 'talvez',
        }),
        throwsA(isA<ProxyConfigException>()),
      );
    });

    test('rejeita modelo com caracteres de caminho e porta inválida', () {
      expect(
        () => ProxyConfig.fromEnvironment(const {
          'GEMINI_API_KEY': 'chave-sintetica',
          'GEMINI_MODEL': '../models/x',
        }),
        throwsA(isA<ProxyConfigException>()),
      );
      expect(
        () => ProxyConfig.fromEnvironment(const {
          'GEMINI_API_KEY': 'chave-sintetica',
          'PROXY_PORT': '80',
        }),
        throwsA(isA<ProxyConfigException>()),
      );
    });
  });

  test('RateLimiter libera de novo quando a janela passa', () {
    var now = DateTime(2026, 11, 24, 12);
    final limiter = RateLimiter(
      maxRequests: 2,
      window: const Duration(minutes: 1),
      clock: () => now,
    );

    expect(limiter.tryAcquire(), isTrue);
    expect(limiter.tryAcquire(), isTrue);
    expect(limiter.tryAcquire(), isFalse);

    now = now.add(const Duration(minutes: 1));

    expect(limiter.tryAcquire(), isTrue);
  });
}
