import 'package:llm_stream_ui/src/core/markdown/markdown_node.dart';

String describeBlocks(List<MarkdownBlock> blocks) =>
    blocks.map(describeBlock).join('\n');

String describeBlock(MarkdownBlock block) => switch (block) {
  HeadingBlock(:final level, :final inlines) =>
    'H$level(${describeInlines(inlines)})',
  ParagraphBlock(:final inlines) => 'P(${describeInlines(inlines)})',
  QuoteBlock(:final inlines) => 'Q(${describeInlines(inlines)})',
  ListBlock(:final items) =>
    'L[${items.map((item) => '${item.depth}${item.marker}${describeInlines(item.inlines)}').join('|')}]',
  CodeBlock(:final language, :final code, :final isClosed) =>
    'C($language,$isClosed,$code)',
  TableBlock(:final header, :final alignments, :final rows) =>
    'T(${header.map(describeInlines).join(',')};${alignments.map((alignment) => alignment.name).join(',')};${rows.map((row) => row.map(describeInlines).join(',')).join('/')})',
  RuleBlock() => 'HR',
};

String describeInlines(List<MarkdownInline> inlines) =>
    inlines.map(describeInline).join();

String describeInline(MarkdownInline inline) => switch (inline) {
  TextInline(:final text) => text,
  StrongInline(:final children) => '<b>${describeInlines(children)}</b>',
  EmphasisInline(:final children) => '<i>${describeInlines(children)}</i>',
  StrikethroughInline(:final children) => '<s>${describeInlines(children)}</s>',
  CodeInline(:final code) => '<code>$code</code>',
  LinkInline(:final children, :final url) =>
    '<a $url>${describeInlines(children)}</a>',
};
