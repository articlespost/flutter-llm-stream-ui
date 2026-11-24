import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/theme/app_spacing.dart';

class UserMessageBubble extends StatelessWidget {
  const UserMessageBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ),
      ),
    );
  }
}
