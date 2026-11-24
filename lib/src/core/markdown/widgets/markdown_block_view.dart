import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_node.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/code_block_view.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/inline_span_builder.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/markdown_style.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/markdown_table_view.dart';

class MarkdownBlockView extends StatelessWidget {
  const MarkdownBlockView({
    super.key,
    required this.block,
    required this.style,
  });

  final MarkdownBlock block;
  final MarkdownStyle style;

  @override
  Widget build(BuildContext context) => switch (block) {
    HeadingBlock(:final level, :final inlines) => Text.rich(
      TextSpan(
        style: style.headingFor(level),
        children: InlineSpanBuilder.build(inlines, style),
      ),
    ),
    ParagraphBlock(:final inlines) => _richText(inlines, style.body),
    QuoteBlock(:final inlines) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: style.quoteBorder, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: _richText(inlines, style.quoteText),
      ),
    ),
    ListBlock(:final items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final item in items) _listItem(item)],
    ),
    final CodeBlock code => CodeBlockView(block: code, style: style),
    final TableBlock table => MarkdownTableView(block: table, style: style),
    RuleBlock() => Divider(color: style.tableBorder, height: 1),
  };

  Widget _richText(List<MarkdownInline> inlines, TextStyle textStyle) =>
      Text.rich(
        TextSpan(
          style: textStyle,
          children: InlineSpanBuilder.build(inlines, style),
        ),
      );

  Widget _listItem(ListItem item) => Padding(
    padding: EdgeInsets.only(left: item.depth * 20.0, bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 26, child: Text(item.marker, style: style.body)),
        Expanded(child: _richText(item.inlines, style.body)),
      ],
    ),
  );
}
