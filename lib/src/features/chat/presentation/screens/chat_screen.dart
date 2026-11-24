import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/di/app_scope.dart';
import 'package:llm_stream_ui/src/core/performance/frame_metrics_monitor.dart';
import 'package:llm_stream_ui/src/core/performance/widgets/performance_hud.dart';
import 'package:llm_stream_ui/src/core/theme/app_spacing.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/response_source.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/controllers/chat_controller.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/screens/chat_screen.strings.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/state/chat_state.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/widgets/chat_composer.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/widgets/empty_chat.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/widgets/message_list.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/widgets/response_source_selector.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/widgets/strategy_selector.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static const String routeName = '/chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _prompt = TextEditingController();
  ChatController? _controller;
  FrameMetricsMonitor? _monitor;
  bool _hadError = false;

  ChatController get _chat => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    _controller = AppScope.of(context).createChatController()
      ..addListener(_onStateChanged);
    _monitor = FrameMetricsMonitor(
      refreshRate: View.of(context).display.refreshRate,
    )..start();
  }

  void _onStateChanged() {
    final failure = _chat.value.failure;
    if (failure != null && !_hadError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ChatScreenStrings.failure(failure.reason))),
      );
    }
    _hadError = failure != null;
  }

  void _send(String prompt) {
    if (_chat.value.isStreaming || prompt.trim().isEmpty) return;
    _monitor?.reset();
    _chat.send(prompt);
    _prompt.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _prompt.dispose();
    _controller
      ?..removeListener(_onStateChanged)
      ..dispose();
    _monitor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ChatScreenStrings.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PerformanceHud(
                        stats: _monitor!,
                        labels: ChatScreenStrings.hudLabels,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ValueListenableBuilder<ChatState>(
                        valueListenable: _chat,
                        builder: (context, state, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StrategySelector(
                              strategy: state.strategy,
                              isEnabled: !state.isStreaming,
                              onChanged: _chat.changeStrategy,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ResponseSourceSelector(
                              source: state.source,
                              isEnabled: !state.isStreaming,
                              isGeminiAvailable: _chat.isAvailable(
                                ResponseSource.gemini,
                              ),
                              onChanged: _chat.changeSource,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<ChatState>(
                    valueListenable: _chat,
                    builder: (context, state, _) => state.messages.isEmpty
                        ? EmptyChat(
                            source: state.source,
                            isGeminiAvailable: _chat.isAvailable(
                              ResponseSource.gemini,
                            ),
                            onSuggestionSelected: _send,
                          )
                        : MessageList(state: state, controller: _chat),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: ValueListenableBuilder<ChatState>(
                    valueListenable: _chat,
                    builder: (context, state, _) => ChatComposer(
                      controller: _prompt,
                      hintText: state.source == ResponseSource.gemini
                          ? ChatScreenStrings.geminiPromptHint
                          : ChatScreenStrings.simulatedPromptHint,
                      isStreaming: state.isStreaming,
                      onSend: () => _send(_prompt.text),
                      onStop: _chat.stop,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
