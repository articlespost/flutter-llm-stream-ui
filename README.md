# UI Reativa para GenAI no Flutter — Streaming de LLM em Markdown sem Jank

Projeto de referência do artigo **"UI Reativa para GenAI no Flutter: Streaming de LLM em Markdown sem Jank"**.

O repositório contém:

- um **app Flutter** de chat que recebe respostas de LLM em streaming e as renderiza em Markdown, com **dois modos de renderização lado a lado** (ingênuo e otimizado) para comparação;
- **duas fontes de resposta**: uma **simulada** (offline, sem chave, usada nas medições) e o **Gemini**, através de um proxy local, com busca no Google opcional;
- um **proxy em Dart puro** (`server/`) que guarda a chave da API fora do app e repassa a resposta do Gemini em SSE;
- um **renderizador de Markdown próprio e incremental**, sem dependências, com títulos, listas, tabelas, citações, blocos de código com destaque de sintaxe e botão de copiar;
- um **HUD de frames** na tela, baseado em `FrameTiming`;
- um **teste de desempenho** com `integration_test` em modo profile, que mede os dois modos e grava os números em JSON;
- **80 testes** automatizados (56 no app e 24 no proxy), incluindo um teste de propriedade que prova que o parse incremental é idêntico ao completo.

> ⚠️ Código de exemplo para estudo, sujeito a revisão antes de qualquer uso em produção.

> 🧪 **A fonte simulada não é uma IA.** Ela tem só **4 respostas prontas**, escolhidas por palavra-chave: **streams em Dart**, **Flow no Kotlin**, **cliente SSE em Python** e a **resposta longa** (teste de estresse). Qualquer outra pergunta, como "o que é Flutter?", recebe a resposta sobre streams em Dart. Para perguntar qualquer coisa, use a fonte **Gemini** (seção 6).

## 📰 Artigo

Este repositório acompanha o artigo **"UI Reativa para GenAI no Flutter: Streaming de LLM em Markdown sem Jank"**, que explica em detalhes a teoria e cada decisão do código:

- onde o custo de um frame realmente está, e o mito do "`setState` a cada chunk";
- por que a abordagem ingênua tem custo quadrático;
- agrupamento por frame, rebuild granular, Markdown incremental e `RepaintBoundary` no lugar certo;
- como ligar um LLM de verdade sem colocar a chave da API no app;
- como medir de verdade, e o que o emulador não consegue medir.

🔗 **Leia o artigo completo no LinkedIn:** *(link em breve)*

---

## Sumário

1. Stack
2. Estrutura do projeto
3. Pré-requisitos
4. Configuração local
5. Rodar o app
6. Os três modos de uso
7. Medir o desempenho
8. Resultados de referência (emulador)
9. Testes
10. Solução de problemas
11. Referências oficiais

---

## 🧱 Stack

| Componente | Versão / observação |
|---|---|
| Flutter / Dart | 3.47.9 / 3.13.7 |
| Gerência de estado | `ValueNotifier` (SDK) |
| Renderização de Markdown | própria, incremental, sem pacote |
| Rede e SSE | `dart:io` (`HttpClient` e `HttpServer`), sem pacote |
| Plugins | `webview_flutter` e `url_launcher`, ambos oficiais do time do Flutter, usados só para exibir as fontes e as sugestões da busca no Google como os termos do Google exigem |
| Testes de desempenho | `integration_test` + `flutter_driver` (SDK) |
| Proxy | Dart puro (`server/`), sem dependências de produção |
| Modelo padrão do proxy | `gemini-3.5-flash-lite` (plano gratuito, sem busca na web) |

## 🗂️ Estrutura do projeto

```text
llm_stream_ui/
├── lib/
│   ├── main.dart                        # Lê o endereço do proxy do arquivo local
│   └── src/
│       ├── core/
│       │   ├── config/                  # local_config.example.dart (versionado) e local_config.dart (local)
│       │   ├── di/                      # AppContainer e AppScope
│       │   ├── markdown/                # Parser incremental, destaque de sintaxe e widgets
│       │   ├── network/                 # HttpClient de streaming e decodificador SSE
│       │   ├── performance/             # FrameMetricsMonitor e HUD
│       │   ├── stream/frame_batcher.dart
│       │   ├── router/
│       │   └── theme/
│       └── features/chat/
│           ├── data/                    # datasources (simulada e Gemini), entities, models, repositories, services
│           └── presentation/            # controllers, state, screens, widgets
├── server/                              # Proxy local do Gemini (Dart puro)
│   ├── bin/gemini_proxy.dart
│   ├── lib/src/                         # Configuração, cliente do Gemini, parser, limite de taxa e servidor
│   └── test/
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
| **Chave do Gemini** | Opcional, só para a fonte "Gemini" (seção 6) |

> Para os números de **raster**, prefira um aparelho físico: a GPU emulada tem um custo mínimo por frame que distorce a comparação (veja [Resultados de referência](#-resultados-de-referência-emulador)).

---

## ⚙️ Configuração local

O endereço do proxy fica num arquivo Dart local, fora do git. Antes de rodar o app pela primeira vez, copie o exemplo:

```bash
cp lib/src/core/config/local_config.example.dart lib/src/core/config/local_config.dart
```

No PowerShell:

```powershell
Copy-Item lib/src/core/config/local_config.example.dart lib/src/core/config/local_config.dart
```

| Valor de `geminiProxyUrl` | Quando usar |
|---|---|
| `http://10.0.2.2:8787` (padrão) | Emulador Android: `10.0.2.2` é o `127.0.0.1` do seu computador |
| `http://127.0.0.1:8787` | Aparelho físico via USB, com `adb reverse tcp:8787 tcp:8787` |
| `''` (vazio) | Desliga a fonte Gemini; o app usa só a fonte simulada |

> O arquivo guarda **só o endereço do proxy**. A chave da API nunca entra no app.

---

## ▶️ Rodar o app

```bash
git clone https://github.com/articlespost/flutter-llm-stream-ui.git
cd flutter-llm-stream-ui
cp lib/src/core/config/local_config.example.dart lib/src/core/config/local_config.dart
flutter pub get
flutter run --profile
```

No VS Code, também dá para rodar com **F5**. Para números confiáveis no HUD, use `--profile`: em debug, o painel mostra um aviso.

Na tela, há dois seletores:

1. **Modo de renderização:** **Ingênuo** ou **Otimizado**;
2. **Fonte da resposta:** **Simulada** (os 4 temas fixos) ou **Gemini** (qualquer pergunta, com o proxy ligado).

Depois, toque numa sugestão ou escreva a pergunta e acompanhe no HUD os frames, o jank e o tempo de build e raster.

---

## 🧭 Os três modos de uso

### Modo 1: Simulada (sem chave, sem internet)

- Escolha **Simulada** no app. Não precisa de chave nem de proxy;
- Responde **só a 4 temas fixos**, escolhidos por palavra-chave:
  - **Streams em Dart:** a resposta padrão, para qualquer pergunta que não caia nos outros temas;
  - **Flow no Kotlin:** perguntas com "kotlin" ou "flow";
  - **Cliente SSE em Python:** perguntas com "python" ou "sse";
  - **Resposta longa:** as três acima repetidas, para o teste de estresse ("estresse" ou "longa");
- É a fonte usada nas medições, porque entrega sempre o mesmo texto, nos mesmos chunks e no mesmo ritmo.

### Modo 2: Gemini gratuito (padrão do proxy)

- Responde **qualquer pergunta**, com o conhecimento do próprio modelo, **sem pesquisar na web**;
- Modelo `gemini-3.5-flash-lite`, **no plano gratuito**;
- Precisa da chave e do proxy ligado (passo a passo abaixo).

### Modo 3: Gemini com busca no Google (opcional)

- Responde com base em pesquisas no Google e mostra as **fontes** e as **sugestões de busca** abaixo da resposta;
- Ligue com `GEMINI_GOOGLE_SEARCH=true`. A busca só é gratuita na família **Gemini 2.5** (`gemini-2.5-flash-lite`, até 500 pedidos por dia), e o acesso a esses modelos está limitado a quem já os usou. Se a sua chave não tiver acesso, o app mostra "Modelo indisponível para esta chave";
- Nos modelos Gemini 3 ou mais novos, a busca **não existe no plano gratuito**: exige faturamento ativo (5.000 buscas grátis por mês, depois US$ 14 por mil, conforme a página de preços em 24/11/2026).

> 🔒 **Privacidade:** no plano gratuito, o Google pode usar o conteúdo enviado para melhorar os produtos. **Não envie dados pessoais ou sigilosos.**

### Passo 1: gerar a chave da API

1. Acesse o **Google AI Studio** (`aistudio.google.com`) e entre com a sua conta Google;
2. Abra a área de **chaves de API** (*Get API key* / *API keys*);
3. Clique em **Create API key** e escolha (ou crie) um projeto do Google Cloud;
4. Copie a chave. Para ficar no plano gratuito, **não ative o faturamento** nesse projeto;
5. Trate a chave como uma senha: nada de commit, print ou mensagem. Se ela vazar, revogue-a e gere outra no mesmo lugar.

> Os nomes dos menus do AI Studio mudam com frequência. Se algum não bater, procure por "API key".

### Passo 2: ligar o proxy

Modo 2 (gratuito, padrão), no PowerShell. A variável vale só para esta janela do terminal, que precisa ficar aberta enquanto você usa o app:

```powershell
cd server
$env:GEMINI_API_KEY = "<cole-a-sua-chave-aqui>"
dart pub get
dart run bin/gemini_proxy.dart
```

No Bash:

```bash
cd server
export GEMINI_API_KEY="<cole-a-sua-chave-aqui>"
dart pub get
dart run bin/gemini_proxy.dart
```

O proxy confirma o modelo e a busca ao iniciar:

```text
Proxy do Gemini em http://127.0.0.1:8787
Modelo: gemini-3.5-flash-lite | Busca no Google: desativada
Ctrl+C para encerrar.
```

Modo 3 (com busca), na mesma janela, depois de parar o proxy com Ctrl+C:

```powershell
$env:GEMINI_MODEL = "gemini-2.5-flash-lite"
$env:GEMINI_GOOGLE_SEARCH = "true"
dart run bin/gemini_proxy.dart
```

Para voltar ao modo 2 nessa mesma janela, remova as duas variáveis (`Remove-Item Env:GEMINI_MODEL, Env:GEMINI_GOOGLE_SEARCH`) ou abra um terminal novo.

| Variável | Padrão | O que faz |
|---|---|---|
| `GEMINI_API_KEY` | — (obrigatória) | Chave do Google AI Studio |
| `GEMINI_MODEL` | `gemini-3.5-flash-lite` | Modelo usado |
| `GEMINI_GOOGLE_SEARCH` | `false` | Liga (`true`) ou desliga (`false`) a busca no Google |
| `PROXY_PORT` | `8787` | Porta local do proxy |

### Passo 3: usar no app

1. Com o proxy no ar, rode o app e escolha **Gemini**;
2. Pergunte o que quiser. A cada pergunta, o terminal do proxy registra uma linha como `POST /v1/completions:stream gemini-3.5-flash-lite search=false ok 2345ms`;
3. Num **aparelho físico** via USB, rode antes `adb reverse tcp:8787 tcp:8787` e use `http://127.0.0.1:8787` no `local_config.dart`.

### Como funciona por dentro

- O **app** envia a pergunta para o **proxy local**, em `POST /v1/completions:stream`;
- O **proxy** lê a chave da variável de ambiente, chama o `streamGenerateContent` do Gemini (com a ferramenta de busca, se ligada) e repassa o texto ao app em **SSE**, pedaço por pedaço;
- Com a busca ligada, o proxy envia no fim as **fontes** e as **sugestões de busca**, que o app exibe abaixo da resposta.

Por que um proxy? A documentação do Gemini diz para **nunca embutir a chave em apps web ou mobile**, porque ela pode ser extraída do pacote instalado, e recomenda um servidor intermediário. O proxy deste projeto também:

- escuta **só em `127.0.0.1`**, ou seja, não fica exposto na rede;
- valida o pedido (JSON, até 2.000 caracteres, corpo de até 16 KB);
- limita a **10 pedidos por minuto** e **2 respostas simultâneas**;
- repete chamadas que falharam por 429 ou 5xx com **backoff exponencial**, respeitando o `Retry-After`;
- aplica **timeouts** de conexão e de inatividade;
- **cancela a chamada ao Gemini** quando o app para a resposta ou fecha a conexão, para não gastar cota à toa;
- não grava a pergunta nem a chave no log; em caso de erro, registra a mensagem devolvida pelo Google, para facilitar o diagnóstico.

### Regras de exibição da busca

Os termos do Gemini exigem mostrar as **Search Suggestions** junto com a resposta, **sem modificá-las**. O trecho chega pronto em HTML (`searchEntryPoint.renderedContent`), e o app o exibe numa webview abaixo da resposta. Os links abrem no navegador do aparelho. As fontes (`groundingChunks`) aparecem como chips clicáveis.

### Em produção

O proxy local é para desenvolvimento. Em produção, ele precisa rodar num servidor seu, com **HTTPS**, **autenticação dos usuários do app** e limites por usuário. A chave continua só no servidor.

---

## 📏 Medir o desempenho

```bash
flutter drive --profile \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/streaming_performance_test.dart
```

O teste usa a **fonte simulada**, que é determinística: mesma resposta, mesmos chunks e mesmo ritmo a cada execução, sem rede nem cota. Ele faz um aquecimento, envia a resposta longa no modo ingênuo e depois no otimizado, e grava o resumo de cada um em `build/streaming_performance.json` (chaves `naive_streaming` e `optimized_streaming`).

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
cd server
dart analyze
dart test
```

Esperado: `No issues found!` nas duas análises, **56 testes** no app e **24 testes** no proxy. Os testes não chamam o Google: o proxy é testado contra um Gemini falso local, e o app contra um proxy falso. Destaques:

- `incremental_markdown_document_test.dart`: 100 divisões aleatórias em chunks provando que o parse incremental é **idêntico** ao completo, e que blocos congelados nunca mudam;
- `streaming_markdown_view_test.dart`: os widgets dos blocos congelados são a **mesma instância** entre frames;
- `chat_controller_test.dart`: no modo otimizado, o estado da tela muda só **2 vezes** por resposta; as fontes da busca ficam na mensagem final;
- `gemini_proxy_data_source_test.dart`: o SSE do proxy vira texto e fontes, e cada erro vira uma falha clara para a tela;
- `server/test/proxy_server_test.dart`: a chave vai só no cabeçalho, a busca só é enviada quando ligada, o retry com backoff, a validação, o limite de taxa e o **cancelamento da chamada ao Gemini** quando o app desiste.

---

## 🧯 Solução de problemas

| Sintoma | Causa | Solução |
|---|---|---|
| Erro de compilação: `local_config.dart` não encontrado | O arquivo local não foi criado | Copie `local_config.example.dart` para `local_config.dart` (seção 4) |
| Perguntei algo e veio a resposta sobre streams em Dart | A fonte **Simulada** só tem 4 respostas prontas | Escolha **Gemini**, com o proxy ligado |
| "Gemini" desabilitado no seletor | `geminiProxyUrl` vazio ou inválido | Preencha o endereço no `local_config.dart` |
| "Não foi possível falar com o proxy do Gemini" | Proxy desligado, porta errada ou aparelho físico sem `adb reverse` | Ligue o proxy (seção 6) e deixe o terminal aberto; no aparelho físico, rode `adb reverse tcp:8787 tcp:8787` |
| O proxy não inicia e pede a `GEMINI_API_KEY` | Variável não definida nesta janela do terminal | Defina `$env:GEMINI_API_KEY` na mesma janela em que roda o proxy |
| "O Gemini recusou a chave da API" | Chave errada, revogada ou sem permissão | Gere outra chave e confira a `GEMINI_API_KEY` |
| "Modelo indisponível para esta chave" | A chave não tem acesso ao modelo (os 2.5 são limitados a quem já os usou) | Volte ao padrão: `gemini-3.5-flash-lite` com `GEMINI_GOOGLE_SEARCH=false`; o log do proxy mostra a mensagem do Google |
| "A cota gratuita do Gemini acabou por agora" | Limite do plano gratuito (por minuto ou por dia) | Espere o limite renovar; o diário renova à meia-noite do Pacífico |
| "Muitos pedidos seguidos" | Limite de 10 pedidos por minuto do proxy | Aguarde um minuto |
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
- [Gemini API: Grounding with Google Search](https://ai.google.dev/gemini-api/docs/google-search)
- [Gemini API: preços](https://ai.google.dev/gemini-api/docs/pricing)
- [Gemini API: chaves de API](https://ai.google.dev/gemini-api/docs/api-key)
- [Gemini API: termos adicionais](https://ai.google.dev/gemini-api/terms)

## 📄 Licença

MIT — veja [LICENSE](LICENSE).
