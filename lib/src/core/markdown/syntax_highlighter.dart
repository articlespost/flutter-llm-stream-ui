enum SyntaxTokenKind { plain, keyword, string, comment, number, type }

typedef SyntaxToken = ({String text, SyntaxTokenKind kind});

abstract final class SyntaxHighlighter {
  static const Set<String> _hashCommentLanguages = {
    'python',
    'py',
    'bash',
    'sh',
    'shell',
    'yaml',
    'yml',
    'ruby',
    'rb',
  };

  static const Map<String, Set<String>> _keywords = {
    'dart': {
      'abstract',
      'as',
      'async',
      'await',
      'base',
      'break',
      'case',
      'catch',
      'class',
      'const',
      'continue',
      'default',
      'do',
      'else',
      'enum',
      'extends',
      'false',
      'final',
      'for',
      'if',
      'implements',
      'import',
      'in',
      'interface',
      'is',
      'late',
      'mixin',
      'new',
      'null',
      'on',
      'required',
      'return',
      'sealed',
      'static',
      'super',
      'switch',
      'sync',
      'this',
      'throw',
      'true',
      'try',
      'var',
      'void',
      'when',
      'while',
      'with',
      'yield',
    },
    'kotlin': {
      'as',
      'break',
      'by',
      'catch',
      'class',
      'companion',
      'continue',
      'data',
      'else',
      'enum',
      'false',
      'finally',
      'for',
      'fun',
      'if',
      'import',
      'in',
      'init',
      'interface',
      'internal',
      'is',
      'lateinit',
      'null',
      'object',
      'override',
      'package',
      'private',
      'protected',
      'public',
      'return',
      'sealed',
      'suspend',
      'this',
      'throw',
      'true',
      'try',
      'val',
      'var',
      'when',
      'while',
    },
    'python': {
      'and',
      'as',
      'async',
      'await',
      'break',
      'class',
      'continue',
      'def',
      'elif',
      'else',
      'except',
      'False',
      'finally',
      'for',
      'from',
      'if',
      'import',
      'in',
      'is',
      'lambda',
      'None',
      'not',
      'or',
      'pass',
      'raise',
      'return',
      'True',
      'try',
      'while',
      'with',
      'yield',
    },
    'javascript': {
      'async',
      'await',
      'break',
      'case',
      'catch',
      'class',
      'const',
      'continue',
      'default',
      'else',
      'export',
      'extends',
      'false',
      'finally',
      'for',
      'from',
      'function',
      'if',
      'import',
      'instanceof',
      'interface',
      'let',
      'new',
      'null',
      'return',
      'switch',
      'this',
      'throw',
      'true',
      'try',
      'type',
      'typeof',
      'undefined',
      'var',
      'while',
    },
    'json': {'true', 'false', 'null'},
  };

  static const Map<String, String> _aliases = {
    'kt': 'kotlin',
    'kts': 'kotlin',
    'py': 'python',
    'js': 'javascript',
    'ts': 'javascript',
    'typescript': 'javascript',
    'jsx': 'javascript',
    'tsx': 'javascript',
  };

  static final RegExp _slashTokens = RegExp(
    r'(//[^\n]*|/\*[\s\S]*?\*/)'
    r'''|("(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*')'''
    r'|(\b\d+(?:\.\d+)?\b)'
    r'|(\b[A-Za-z_]\w*\b)',
  );

  static final RegExp _hashTokens = RegExp(
    r'(#[^\n]*)'
    r'''|("(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*')'''
    r'|(\b\d+(?:\.\d+)?\b)'
    r'|(\b[A-Za-z_]\w*\b)',
  );

  static List<SyntaxToken> tokenize(String code, String language) {
    final normalized =
        _aliases[language.toLowerCase()] ?? language.toLowerCase();
    final keywords = _keywords[normalized] ?? const <String>{};
    final pattern = _hashCommentLanguages.contains(normalized)
        ? _hashTokens
        : _slashTokens;
    final tokens = <SyntaxToken>[];
    var cursor = 0;
    for (final match in pattern.allMatches(code)) {
      if (match.start > cursor) {
        tokens.add((
          text: code.substring(cursor, match.start),
          kind: SyntaxTokenKind.plain,
        ));
      }
      tokens.add((text: match[0]!, kind: _kindOf(match, keywords)));
      cursor = match.end;
    }
    if (cursor < code.length) {
      tokens.add((text: code.substring(cursor), kind: SyntaxTokenKind.plain));
    }
    return tokens;
  }

  static SyntaxTokenKind _kindOf(RegExpMatch match, Set<String> keywords) {
    if (match[1] != null) return SyntaxTokenKind.comment;
    if (match[2] != null) return SyntaxTokenKind.string;
    if (match[3] != null) return SyntaxTokenKind.number;
    final word = match[4]!;
    if (keywords.contains(word)) return SyntaxTokenKind.keyword;
    if (word.startsWith(RegExp('[A-Z]'))) return SyntaxTokenKind.type;
    return SyntaxTokenKind.plain;
  }
}
