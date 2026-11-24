import 'package:flutter_test/flutter_test.dart';
import 'package:llm_stream_ui/src/core/markdown/syntax_highlighter.dart';

void main() {
  Map<String, SyntaxTokenKind> kindsOf(String code, String language) => {
    for (final token in SyntaxHighlighter.tokenize(code, language))
      if (token.kind != SyntaxTokenKind.plain) token.text: token.kind,
  };

  test('classifica palavras-chave, tipos, strings, números e comentários', () {
    final kinds = kindsOf(
      "final Duration delay = parse('42', 10); // atraso",
      'dart',
    );

    expect(kinds['final'], SyntaxTokenKind.keyword);
    expect(kinds['Duration'], SyntaxTokenKind.type);
    expect(kinds["'42'"], SyntaxTokenKind.string);
    expect(kinds['10'], SyntaxTokenKind.number);
    expect(kinds['// atraso'], SyntaxTokenKind.comment);
  });

  test('usa comentário com # nas linguagens que o adotam', () {
    expect(
      kindsOf('def run(): # executa', 'python')['# executa'],
      SyntaxTokenKind.comment,
    );
  });

  test('resolve apelidos de linguagem', () {
    expect(kindsOf('val x = 1', 'kt')['val'], SyntaxTokenKind.keyword);
  });

  test('reconstrói o código original sem perder caracteres', () {
    const code = 'for (event in events) {\n  println("ok")\n}';
    final rebuilt = SyntaxHighlighter.tokenize(
      code,
      'kotlin',
    ).map((token) => token.text).join();

    expect(rebuilt, code);
  });
}
