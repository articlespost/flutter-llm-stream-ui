import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/markdown/syntax_highlighter.dart';

@immutable
class MarkdownStyle {
  const MarkdownStyle({
    required this.body,
    required this.headings,
    required this.code,
    required this.inlineCodeBackground,
    required this.codeBackground,
    required this.codeHeaderBackground,
    required this.codeHeaderText,
    required this.link,
    required this.quoteBorder,
    required this.quoteText,
    required this.tableBorder,
    required this.tableHeaderBackground,
    required this.syntaxColors,
    required this.blockSpacing,
  });

  factory MarkdownStyle.of(ThemeData theme) {
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final body = (text.bodyLarge ?? const TextStyle()).copyWith(
      height: 1.55,
      color: scheme.onSurface,
    );
    const monospace = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Menlo', 'Consolas', 'Courier New'],
      fontSize: 13.5,
      height: 1.5,
    );
    return MarkdownStyle(
      body: body,
      headings: [
        (text.headlineSmall ?? body).copyWith(fontWeight: FontWeight.w700),
        (text.titleLarge ?? body).copyWith(fontWeight: FontWeight.w700),
        (text.titleMedium ?? body).copyWith(fontWeight: FontWeight.w700),
      ],
      code: monospace.copyWith(
        color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2328),
      ),
      inlineCodeBackground: scheme.surfaceContainerHighest,
      codeBackground: isDark
          ? const Color(0xFF0D1117)
          : const Color(0xFFF6F8FA),
      codeHeaderBackground: isDark
          ? const Color(0xFF161B22)
          : const Color(0xFFEAEEF2),
      codeHeaderText: scheme.onSurfaceVariant,
      link: body.copyWith(
        color: scheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: scheme.primary,
      ),
      quoteBorder: scheme.primary,
      quoteText: body.copyWith(
        color: scheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      tableBorder: scheme.outlineVariant,
      tableHeaderBackground: scheme.surfaceContainerHigh,
      syntaxColors: isDark
          ? const {
              SyntaxTokenKind.keyword: Color(0xFFFF7B72),
              SyntaxTokenKind.string: Color(0xFFA5D6FF),
              SyntaxTokenKind.comment: Color(0xFF8B949E),
              SyntaxTokenKind.number: Color(0xFF79C0FF),
              SyntaxTokenKind.type: Color(0xFFFFA657),
            }
          : const {
              SyntaxTokenKind.keyword: Color(0xFFCF222E),
              SyntaxTokenKind.string: Color(0xFF0A3069),
              SyntaxTokenKind.comment: Color(0xFF6E7781),
              SyntaxTokenKind.number: Color(0xFF0550AE),
              SyntaxTokenKind.type: Color(0xFF953800),
            },
      blockSpacing: 12,
    );
  }

  final TextStyle body;
  final List<TextStyle> headings;
  final TextStyle code;
  final Color inlineCodeBackground;
  final Color codeBackground;
  final Color codeHeaderBackground;
  final Color codeHeaderText;
  final TextStyle link;
  final Color quoteBorder;
  final TextStyle quoteText;
  final Color tableBorder;
  final Color tableHeaderBackground;
  final Map<SyntaxTokenKind, Color> syntaxColors;
  final double blockSpacing;

  TextStyle headingFor(int level) =>
      headings[(level - 1).clamp(0, headings.length - 1)];
}
