import 'package:flutter/painting.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_node.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/markdown_style.dart';

abstract final class InlineSpanBuilder {
  static List<InlineSpan> build(
    List<MarkdownInline> inlines,
    MarkdownStyle style,
  ) => [for (final inline in inlines) _spanOf(inline, style)];

  static InlineSpan _spanOf(MarkdownInline inline, MarkdownStyle style) =>
      switch (inline) {
        TextInline(:final text) => TextSpan(text: text),
        StrongInline(:final children) => TextSpan(
          style: const TextStyle(fontWeight: FontWeight.w700),
          children: build(children, style),
        ),
        EmphasisInline(:final children) => TextSpan(
          style: const TextStyle(fontStyle: FontStyle.italic),
          children: build(children, style),
        ),
        StrikethroughInline(:final children) => TextSpan(
          style: const TextStyle(decoration: TextDecoration.lineThrough),
          children: build(children, style),
        ),
        CodeInline(:final code) => TextSpan(
          text: ' $code ',
          style: style.code.copyWith(
            fontSize: (style.body.fontSize ?? 16) * 0.88,
            backgroundColor: style.inlineCodeBackground,
          ),
        ),
        LinkInline(:final children) => TextSpan(
          style: style.link,
          children: build(children, style),
        ),
      };
}
