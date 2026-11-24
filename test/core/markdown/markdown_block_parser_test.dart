import 'package:flutter_test/flutter_test.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_block_parser.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_node.dart';

import '../../helpers/markdown_debug.dart';

void main() {
  String parse(String source) =>
      describeBlocks(MarkdownBlockParser.parse(source));

  test('títulos e parágrafo com quebras de linha suaves', () {
    expect(
      parse('# Título\nlinha um\nlinha dois'),
      'H1(Título)\nP(linha um linha dois)',
    );
  });

  test(
    'lista ordenada preserva o número inicial e lista aninhada a profundidade',
    () {
      expect(parse('3. três\n4. quatro'), 'L[03.três|04.quatro]');
      expect(parse('- pai\n  - filho'), 'L[0•pai|1◦filho]');
    },
  );

  test('linha indentada continua o item anterior da lista', () {
    expect(parse('- começo\n  continuação'), 'L[0•começo continuação]');
  });

  test('bloco de código fechado e aberto', () {
    expect(parse('```dart\nfinal a = 1;\n```'), 'C(dart,true,final a = 1;)');
    expect(parse('```kotlin\nval a = 1'), 'C(kotlin,false,val a = 1)');
  });

  test('conteúdo de bloco de código não é interpretado como Markdown', () {
    expect(
      parse('```\n# não é título\n- nem lista\n```'),
      'C(,true,# não é título\n- nem lista)',
    );
  });

  test('tabela com alinhamentos e células formatadas', () {
    expect(
      parse('| A | B | C |\n|:---|:---:|---:|\n| `x` | **y** | z |'),
      'T(A,B,C;start,center,end;<code>x</code>,<b>y</b>,z)',
    );
  });

  test('linha com barra sem separador continua sendo parágrafo', () {
    expect(parse('| A | B |'), 'P(| A | B |)');
  });

  test('citação, régua e parágrafo interrompido por título', () {
    expect(
      parse('> uma\n> citação\n\n---\n\ntexto\n## Título'),
      'Q(uma citação)\nHR\nP(texto)\nH2(Título)',
    );
  });

  test('devolve uma lista imutável', () {
    final blocks = MarkdownBlockParser.parse('texto');
    expect(() => blocks.add(const RuleBlock()), throwsUnsupportedError);
  });
}
