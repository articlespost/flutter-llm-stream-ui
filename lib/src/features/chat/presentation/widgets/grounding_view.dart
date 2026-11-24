import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/theme/app_spacing.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/search_grounding.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/screens/chat_screen.strings.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/widgets/search_suggestions_view.dart';
import 'package:url_launcher/url_launcher.dart';

class GroundingView extends StatelessWidget {
  const GroundingView({super.key, required this.grounding});

  final SearchGrounding grounding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final renderedContent = grounding.renderedContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grounding.sources.isNotEmpty) ...[
          Text(
            ChatScreenStrings.sources,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (index, source) in grounding.sources.indexed)
                ActionChip(
                  avatar: Text('${index + 1}'),
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(source.title, overflow: TextOverflow.ellipsis),
                  ),
                  onPressed: () => _open(context, source.uri),
                ),
            ],
          ),
        ],
        if (renderedContent != null && renderedContent.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SearchSuggestionsView(renderedContent: renderedContent),
        ],
      ],
    );
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(ChatScreenStrings.openLinkError)),
      );
    }
  }
}
