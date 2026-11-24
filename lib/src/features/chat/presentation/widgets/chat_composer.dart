import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/theme/app_spacing.dart';
import 'package:llm_stream_ui/src/features/chat/data/services/chat_service.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/screens/chat_screen.strings.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !isStreaming,
            minLines: 1,
            maxLines: 4,
            maxLength: ChatService.maxPromptLength,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: ChatScreenStrings.promptHint,
              counterText: '',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (isStreaming)
          IconButton.filledTonal(
            tooltip: ChatScreenStrings.stop,
            onPressed: onStop,
            icon: const Icon(Icons.stop_rounded),
          )
        else
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => IconButton.filled(
              tooltip: ChatScreenStrings.send,
              onPressed: value.text.trim().isEmpty ? null : onSend,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ),
      ],
    );
  }
}
