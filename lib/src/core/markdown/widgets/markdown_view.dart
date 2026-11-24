import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_block_parser.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/markdown_block_view.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/markdown_style.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/streaming_cursor.dart';

class MarkdownView extends StatelessWidget {
  const MarkdownView({
    super.key,
    required this.source,
    this.showCursor = false,
  });

  final String source;
  final bool showCursor;

  @override
  Widget build(BuildContext context) {
    final style = MarkdownStyle.of(Theme.of(context));
    final blocks = MarkdownBlockParser.parse(source);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks)
          Padding(
            padding: EdgeInsets.only(bottom: style.blockSpacing),
            child: MarkdownBlockView(block: block, style: style),
          ),
        if (showCursor)
          const Align(
            alignment: Alignment.centerLeft,
            child: StreamingCursor(),
          ),
      ],
    );
  }
}
