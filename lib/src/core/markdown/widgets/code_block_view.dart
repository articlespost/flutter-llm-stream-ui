import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_node.dart';
import 'package:llm_stream_ui/src/core/markdown/syntax_highlighter.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/markdown_style.dart';

class CodeBlockView extends StatelessWidget {
  const CodeBlockView({super.key, required this.block, required this.style});

  final CodeBlock block;
  final MarkdownStyle style;

  @override
  Widget build(BuildContext context) {
    final language = block.language.isEmpty ? 'code' : block.language;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.codeBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.tableBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: style.codeHeaderBackground,
              child: Padding(
                padding: const EdgeInsets.only(left: 14, right: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        language,
                        style: style.code.copyWith(
                          color: style.codeHeaderText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (block.isClosed)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .copyButtonLabel,
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        color: style.codeHeaderText,
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: block.code)),
                      )
                    else
                      const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(14),
              child: Text.rich(
                TextSpan(
                  style: style.code,
                  children: block.isClosed ? _highlighted() : null,
                  text: block.isClosed ? null : block.code,
                ),
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _highlighted() => [
    for (final token in SyntaxHighlighter.tokenize(block.code, block.language))
      TextSpan(
        text: token.text,
        style: switch (style.syntaxColors[token.kind]) {
          final color? => TextStyle(
            color: color,
            fontStyle: token.kind == SyntaxTokenKind.comment
                ? FontStyle.italic
                : null,
          ),
          null => null,
        },
      ),
  ];
}
