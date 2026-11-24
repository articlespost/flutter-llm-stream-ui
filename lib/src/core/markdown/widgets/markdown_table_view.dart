import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_node.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/inline_span_builder.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/markdown_style.dart';

class MarkdownTableView extends StatelessWidget {
  const MarkdownTableView({
    super.key,
    required this.block,
    required this.style,
  });

  final TableBlock block;
  final MarkdownStyle style;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(
          color: style.tableBorder,
          borderRadius: BorderRadius.circular(8),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(color: style.tableHeaderBackground),
            children: [
              for (var column = 0; column < block.header.length; column++)
                _cell(
                  block.header[column],
                  block.alignments[column],
                  isHeader: true,
                ),
            ],
          ),
          for (final row in block.rows)
            TableRow(
              children: [
                for (var column = 0; column < row.length; column++)
                  _cell(row[column], block.alignments[column]),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(
    List<MarkdownInline> inlines,
    TableAlignment alignment, {
    bool isHeader = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Text.rich(
      TextSpan(
        style: isHeader
            ? style.body.copyWith(fontWeight: FontWeight.w700)
            : style.body,
        children: InlineSpanBuilder.build(inlines, style),
      ),
      textAlign: switch (alignment) {
        TableAlignment.start => TextAlign.start,
        TableAlignment.center => TextAlign.center,
        TableAlignment.end => TextAlign.end,
      },
    ),
  );
}
