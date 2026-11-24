import 'package:flutter_test/flutter_test.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_inline_parser.dart';

import '../../helpers/markdown_debug.dart';

void main() {
  String parse(String source) =>
      describeInlines(MarkdownInlineParser.parse(source));

  test('reconhece negrito, itálico, tachado e código inline', () {
    expect(
      parse('**forte** e *leve* com ~~velho~~ e `code`'),
      '<b>forte</b> e <i>leve</i> com <s>velho</s> e <code>code</code>',
    );
  });

  test('aninha itálico dentro de negrito', () {
    expect(parse('**muito *bom***'), '<b>muito <i>bom</i></b>');
  });

  test('reconhece links com texto formatado', () {
    expect(
      parse('veja a [**doc**](https://example.com)'),
      'veja a <a https://example.com><b>doc</b></a>',
    );
  });

  test('não trata snake_case como itálico', () {
    expect(parse('use max_output_tokens aqui'), 'use max_output_tokens aqui');
  });

  test('não trata multiplicação com espaços como itálico', () {
    expect(parse('2 * 3 * 4'), '2 * 3 * 4');
  });

  test('marcadores sem fechamento viram texto literal durante o streaming', () {
    expect(parse('texto **incomple'), 'texto **incomple');
    expect(parse('chamada `incomple'), 'chamada `incomple');
  });
}
