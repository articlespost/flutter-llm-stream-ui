import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/markdown_view.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/streaming_markdown_view.dart';
import 'package:llm_stream_ui/src/core/theme/app_spacing.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/chat_message.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/controllers/chat_controller.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/state/chat_state.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/widgets/assistant_message.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/widgets/user_message_bubble.dart';

class MessageList extends StatelessWidget {
  const MessageList({super.key, required this.state, required this.controller});

  final ChatState state;
  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final messages = state.messages;

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return Padding(
          key: ValueKey(message.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: switch (message.role) {
            MessageRole.user => UserMessageBubble(text: message.text),
            MessageRole.assistant => _assistant(message),
          },
        );
      },
    );
  }

  Widget _assistant(ChatMessage message) {
    final isActive = message.id == controller.activeMessageId;
    final snapshot = controller.snapshotFor(message.id);
    final content = switch (state.strategy) {
      RenderingStrategy.optimized when snapshot != null =>
        StreamingMarkdownView(snapshot: snapshot),
      _ => MarkdownView(source: message.text, showCursor: isActive),
    };
    return AssistantMessage(
      content: content,
      copyText: isActive ? null : message.text,
    );
  }
}
