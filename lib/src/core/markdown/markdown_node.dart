sealed class MarkdownInline {
  const MarkdownInline();
}

final class TextInline extends MarkdownInline {
  const TextInline(this.text);

  final String text;
}

final class StrongInline extends MarkdownInline {
  const StrongInline(this.children);

  final List<MarkdownInline> children;
}

final class EmphasisInline extends MarkdownInline {
  const EmphasisInline(this.children);

  final List<MarkdownInline> children;
}

final class StrikethroughInline extends MarkdownInline {
  const StrikethroughInline(this.children);

  final List<MarkdownInline> children;
}

final class CodeInline extends MarkdownInline {
  const CodeInline(this.code);

  final String code;
}

final class LinkInline extends MarkdownInline {
  const LinkInline({required this.children, required this.url});

  final List<MarkdownInline> children;
  final String url;
}

sealed class MarkdownBlock {
  const MarkdownBlock();
}

final class HeadingBlock extends MarkdownBlock {
  const HeadingBlock({required this.level, required this.inlines});

  final int level;
  final List<MarkdownInline> inlines;
}

final class ParagraphBlock extends MarkdownBlock {
  const ParagraphBlock(this.inlines);

  final List<MarkdownInline> inlines;
}

final class QuoteBlock extends MarkdownBlock {
  const QuoteBlock(this.inlines);

  final List<MarkdownInline> inlines;
}

final class ListItem {
  const ListItem({
    required this.depth,
    required this.marker,
    required this.inlines,
  });

  final int depth;
  final String marker;
  final List<MarkdownInline> inlines;
}

final class ListBlock extends MarkdownBlock {
  const ListBlock(this.items);

  final List<ListItem> items;
}

final class CodeBlock extends MarkdownBlock {
  const CodeBlock({
    required this.language,
    required this.code,
    required this.isClosed,
  });

  final String language;
  final String code;
  final bool isClosed;
}

enum TableAlignment { start, center, end }

final class TableBlock extends MarkdownBlock {
  const TableBlock({
    required this.header,
    required this.alignments,
    required this.rows,
  });

  final List<List<MarkdownInline>> header;
  final List<TableAlignment> alignments;
  final List<List<List<MarkdownInline>>> rows;
}

final class RuleBlock extends MarkdownBlock {
  const RuleBlock();
}
