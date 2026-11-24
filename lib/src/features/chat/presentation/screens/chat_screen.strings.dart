import 'package:llm_stream_ui/src/core/performance/widgets/performance_hud.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_failure.dart';

abstract final class ChatScreenStrings {
  static String get title => 'Streaming de LLM sem jank';
  static String get naive => 'Ingênuo';
  static String get optimized => 'Otimizado';
  static String get simulatedSource => 'Simulada';
  static String get geminiSource => 'Gemini';
  static String get geminiNotConfigured =>
      'Configure o proxy do Gemini para usar esta fonte (veja o README).';
  static String get simulatedPromptHint => 'Fonte simulada: só 4 temas fixos';
  static String get geminiPromptHint => 'Pergunte qualquer coisa ao Gemini';
  static String get send => 'Enviar';
  static String get stop => 'Parar';
  static String get copy => 'Copiar resposta';
  static String get copied => 'Resposta copiada';
  static String get sources => 'Fontes';
  static String get openLinkError => 'Não foi possível abrir o link.';
  static String get emptyTitle => 'Compare os dois modos de renderização';
  static String get emptyMessage =>
      'Escolha um modo, envie uma pergunta e acompanhe os frames no painel acima.';
  static String get simulatedNotice =>
      'A fonte simulada não é uma IA: ela tem só 4 respostas prontas, '
      'escolhidas por palavra-chave (streams em Dart, Flow no Kotlin, '
      'cliente SSE em Python e a resposta longa). Qualquer outra pergunta '
      'recebe a resposta sobre streams em Dart.';
  static String get geminiSetupNotice =>
      'Para perguntar qualquer coisa, ligue o proxy do Gemini e escolha '
      '"Gemini". O passo a passo está no README.';
  static String get geminiNotice =>
      'O Gemini responde qualquer pergunta pelo proxy local. Por padrão, ele '
      'usa o próprio conhecimento, sem pesquisar na web; com a busca no '
      'Google ligada no proxy, a resposta traz as fontes. No plano gratuito, '
      'o Google pode usar o conteúdo enviado para melhorar os produtos: não '
      'envie dados pessoais ou sigilosos.';

  static List<String> get suggestions => const [
    'Explique streams em Dart',
    'Como é o Flow no Kotlin?',
    'Mostre um cliente SSE em Python',
    'Resposta longa (teste de estresse)',
  ];

  static List<String> get geminiSuggestions => const [
    'O que é Flutter?',
    'Explique o ciclo de vida de um StatefulWidget',
    'Compare Flutter e Kotlin Multiplatform',
  ];

  static String failure(CompletionFailureReason reason) => switch (reason) {
    CompletionFailureReason.sourceUnavailable => 'Não foi possível falar com o proxy do Gemini. Confira se ele está rodando.',
    CompletionFailureReason.quotaExceeded =>
      'A cota gratuita do Gemini acabou por agora. Tente mais tarde.',
    CompletionFailureReason.rateLimited =>
      'Muitos pedidos seguidos. Aguarde um minuto e tente de novo.',
    CompletionFailureReason.permissionDenied =>
      'O Gemini recusou a chave da API. Confira a GEMINI_API_KEY do proxy.',
    CompletionFailureReason.modelNotFound =>
      'Modelo indisponível para esta chave. Troque o GEMINI_MODEL do proxy.',
    CompletionFailureReason.blocked =>
      'A resposta foi bloqueada pelos filtros de segurança do Gemini.',
    CompletionFailureReason.interrupted =>
      'A resposta foi interrompida. Tente novamente.',
  };

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
