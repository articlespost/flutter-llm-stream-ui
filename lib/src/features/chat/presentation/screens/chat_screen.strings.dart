import 'package:llm_stream_ui/src/core/performance/widgets/performance_hud.dart';

abstract final class ChatScreenStrings {
  static String get title => 'Streaming de LLM sem jank';
  static String get naive => 'Ingênuo';
  static String get optimized => 'Otimizado';
  static String get promptHint => 'Pergunte algo à IA';
  static String get send => 'Enviar';
  static String get stop => 'Parar';
  static String get copy => 'Copiar resposta';
  static String get copied => 'Resposta copiada';
  static String get emptyTitle => 'Compare os dois modos de renderização';
  static String get emptyMessage =>
      'Escolha um modo, envie uma pergunta e acompanhe os frames no painel acima.';
  static String get streamError =>
      'A resposta foi interrompida. Tente novamente.';

  static List<String> get suggestions => const [
    'Explique streams em Dart',
    'Como é o Flow no Kotlin?',
    'Mostre um cliente SSE em Python',
    'Resposta longa (teste de estresse)',
  ];

  static PerformanceHudLabels get hudLabels => const PerformanceHudLabels(
    frames: 'frames',
    jank: 'jank',
    build: 'build',
    raster: 'raster',
    worst: 'pior',
    budget: 'orçamento',
    debugWarning: 'Modo debug: meça em --profile para números reais.',
  );
}
