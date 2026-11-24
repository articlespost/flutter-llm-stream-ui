import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llm_stream_ui/src/core/theme/app_spacing.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/screens/chat_screen.strings.dart';

class AssistantMessage extends StatelessWidget {
  const AssistantMessage({
    super.key,
    required this.content,
    required this.copyText,
  });

  final Widget content;
  final String? copyText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final copyText = this.copyText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: scheme.secondaryContainer,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 16,
            color: scheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              if (copyText != null && copyText.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: ChatScreenStrings.copy,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    color: scheme.onSurfaceVariant,
                    icon: const Icon(Icons.copy_all_rounded),
                    onPressed: () => _copy(context, copyText),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(SnackBar(content: Text(ChatScreenStrings.copied)));
  }
}
