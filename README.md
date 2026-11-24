# UI Reativa para GenAI no Flutter — Streaming de LLM em Markdown sem Jank

Projeto de referência do artigo **"UI Reativa para GenAI no Flutter: Streaming de LLM em Markdown sem Jank"**.

O repositório contém:

- um **app Flutter** de chat que recebe respostas de LLM em streaming e as renderiza em Markdown, com **dois modos lado a lado** (ingênuo e otimizado) para comparação;
- um **renderizador de Markdown próprio e incremental**, sem dependências, com títulos, listas, tabelas, citações, blocos de código com destaque de sintaxe e botão de copiar;
- um **HUD de frames** na tela, baseado em `FrameTiming`;
- um **teste de desempenho** com `integration_test` em modo profile, que mede os dois modos e grava os números em JSON;
- **41 testes** automatizados, incluindo um teste de propriedade que prova que o parse incremental é idêntico ao completo.

> ⚠️ Código de exemplo para estudo, sujeito a revisão antes de qualquer uso em produção. A fonte de streaming é **simulada** (sem chave de API e sem custo); trocar por Gemini, Claude ou OpenAI muda apenas o datasource.

## 📰 Artigo

Este repositório acompanha o artigo **"UI Reativa para GenAI no Flutter: Streaming de LLM em Markdown sem Jank"**, que explica em detalhes a teoria e cada decisão do código:

- onde o custo de um frame realmente está, e o mito do "`setState` a cada chunk";
- por que a abordagem ingênua tem custo quadrático;
- agrupamento por frame, rebuild granular, Markdown incremental e `RepaintBoundary` no lugar certo;
- como medir de verdade, e o que o emulador não consegue medir.

🔗 **Leia o artigo completo no LinkedIn:** *(link em breve)*

---

## Sumário

1. Stack
2. Estrutura do projeto
3. Pré-requisitos
4. Rodar o app
5. Medir o desempenho
6. Resultados de referência (emulador)
7. Testes
8. Solução de problemas
9. Referências oficiais

---

## 🧱 Stack

| Componente | Versão |
|---|---|
| Flutter / Dart | 3.47.9 / 3.13.7 |
| Gerência de estado | `ValueNotifier` (SDK) |
| Renderização de Markdown | própria, incremental |
| Dependências de terceiros | nenhuma |
| Testes de desempenho | `integration_test` + `flutter_driver` (SDK) |

## 🗂️ Estrutura do projeto

```text
llm_stream_ui/
├── lib/src/
│   ├── core/
│   │   ├── di/                          # AppContainer e AppScope
│   │   ├── markdown/
│   │   │   ├── markdown_node.dart       # Modelo de blocos e inlines
│   │   │   ├── markdown_block_parser.dart
│   │   │   ├── markdown_inline_parser.dart
│   │   │   ├── incremental_markdown_document.dart  # Blocos congelados + trecho final
│   │   │   ├── syntax_highlighter.dart
│   │   │   └── widgets/                 # MarkdownView (ingênuo), StreamingMarkdownView (otimizado)
│   │   ├── performance/                 # FrameMetricsMonitor e HUD
│   │   ├── stream/frame_batcher.dart    # Agrupa chunks por frame
│   │   ├── router/
│   │   └── theme/
│   └── features/chat/
│       ├── data/                        # datasource (fonte simulada), entities, models, repositories, services
│       └── presentation/                # controllers, state, screens, widgets
├── integration_test/
│   └── streaming_performance_test.dart  # Mede ingênuo x otimizado em modo profile
├── test_driver/perf_driver.dart         # Grava build/streaming_performance.json
└── test/                                # Espelha a estrutura de lib/
```

---

## 📋 Pré-requisitos

| Ferramenta | Versão / observação |
|---|---|
| **Flutter SDK** | 3.47+ (Dart 3.13+) |
| **Android SDK** ou **Xcode** | Para rodar em emulador, simulador ou aparelho |
| **Aparelho de teste** | **Emulador funciona.** O projeto não depende de hardware específico |

> Para os números de **raster**, prefira um aparelho físico: a GPU emulada tem um custo mínimo por frame que distorce a comparação (veja [Resultados de referência](#-resultados-de-referência-emulador)).

---

## ▶️ Rodar o app

```bash
git clone https://github.com/articlespost/flutter-llm-stream-ui.git
cd flutter-llm-stream-ui
flutter pub get
flutter run --profile
```

No VS Code, também dá para rodar com **F5**. Para números confiáveis no HUD, use `--profile`: em debug, o painel mostra um aviso.

1. Escolha **Ingênuo** ou **Otimizado** no seletor;
2. Toque em **"Resposta longa (teste de estresse)"**;
3. Acompanhe no HUD os frames, o jank e o tempo de build e raster.

---

## 📏 Medir o desempenho

```bash
flutter drive --profile \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/streaming_performance_test.dart
```

O teste faz um aquecimento, envia a resposta longa no modo ingênuo e depois no otimizado, e grava o resumo de cada um em `build/streaming_performance.json` (chaves `naive_streaming` e `optimized_streaming`).

| Métrica no JSON | O que significa |
|---|---|
| `average_frame_build_time_millis` | Tempo médio da thread de UI (build, layout e paint) |
| `90th_percentile_frame_build_time_millis` / `99th_...` | A cauda, onde o jank aparece |
| `missed_frame_build_budget_count` | Frames com build acima do orçamento |
| `average_frame_rasterizer_time_millis` | Tempo médio da thread de raster |
| `frame_count` | Frames entregues durante a resposta |

> O emulador varia muito entre execuções. Rode **pelo menos 3 vezes** e compare medianas.

---

## 📊 Resultados de referência (emulador)

Emulador Pixel 4 (Android 13, API 33, x86_64), modo profile, Flutter 3.47.9. Resposta longa de 8.372 caracteres (~1.700 chunks a cada 8 ms). Medianas de 6 rodadas do modo ingênuo e 3 do otimizado.

| Métrica | Ingênuo | Otimizado | Variação |
|---|---|---|---|
| Build médio | 10,8 ms | 3,0 ms | −72% |
| Build p90 | 17,3 ms | 4,3 ms | −75% |
| Build p99 | 26,1 ms | 7,2 ms | −72% |
| Frames com build acima do orçamento | 16,9% | 0,1% | — |
| Frames entregues na mesma resposta | 1.310 | 1.630 | +24% |
| Duração do teste (mesma resposta) | 39,5 s | 32,5 s | −18% |

**Sobre o raster:** no emulador, até uma tela com apenas um indicador de progresso girando custa ~12 ms de raster por frame (16% dos frames acima do orçamento). Esse é o piso da GPU emulada. O raster do modo otimizado ficou nesse piso; por isso, **valide o raster em aparelho físico**.

---

## 🧪 Testes

```bash
flutter analyze
flutter test
```

Esperado: `No issues found!` e `All tests passed!` (41 testes). Destaques:

- `incremental_markdown_document_test.dart`: 100 divisões aleatórias em chunks provando que o parse incremental é **idêntico** ao completo, e que blocos congelados nunca mudam;
- `streaming_markdown_view_test.dart`: os widgets dos blocos congelados são a **mesma instância** entre frames;
- `chat_controller_test.dart`: no modo otimizado, o estado da tela muda só **2 vezes** por resposta;
- `frame_metrics_monitor_test.dart`: o critério de jank (build ou raster acima do orçamento).

---

## 🧯 Solução de problemas

| Sintoma | Causa | Solução |
|---|---|---|
| HUD com tempos altos em qualquer modo | App em modo debug | Rode com `--profile` |
| `watchPerformance` falha com `Failed to connect to VM Service` | No emulador, o app não consegue conectar no VM Service para contar GC | O teste do projeto coleta `FrameTiming` direto, sem essa conexão |
| Raster do otimizado pior que o do ingênuo no emulador | Piso de raster da GPU emulada; o ingênuo entrega menos frames | Compare o build; valide o raster em aparelho físico |
| Teste de widget trava ao parar o streaming | Cancelar um gerador `async*` espera o `Future.delayed` atual, que não avança no tempo simulado | Dispare o cancelamento, avance com `tester.pump(...)` e depois aguarde |
| Números muito diferentes entre execuções | Variação do emulador | Rode várias vezes e use a mediana |

## 📚 Referências oficiais

- [Performance best practices (Flutter)](https://docs.flutter.dev/perf/best-practices)
- [Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance)
- [`RepaintBoundary`](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)
- [`FrameTiming`](https://api.flutter.dev/flutter/dart-ui/FrameTiming-class.html)
- [Integration testing e performance profiling](https://docs.flutter.dev/cookbook/testing/integration/profiling)

## 📄 Licença

MIT — veja [LICENSE](LICENSE).
