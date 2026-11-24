import 'package:llm_stream_ui/src/core/markdown/markdown_inline_parser.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_node.dart';

abstract final class MarkdownBlockParser {
  static List<MarkdownBlock> parse(String source) =>
      _BlockScanner(source.replaceAll('\r', '').split('\n')).scan();

  static final RegExp fenceOpening = RegExp(
    r'^ {0,3}(`{3,}|~{3,})\s*([^\s`]*)',
  );

  static bool closesFence(String line, String fence) {
    final trimmed = line.trim();
    return trimmed.length >= fence.length &&
        trimmed.split('').every((character) => character == fence[0]);
  }
}

class _BlockScanner {
  _BlockScanner(this._lines);

  final List<String> _lines;
  final List<MarkdownBlock> _blocks = [];
  int _index = 0;

  static final RegExp _heading = RegExp(r'^ {0,3}(#{1,6})\s+(.*?)\s*#*\s*$');
  static final RegExp _rule = RegExp(r'^ {0,3}([-*_])(\s*\1){2,}\s*$');
  static final RegExp _quote = RegExp(r'^ {0,3}>\s?(.*)$');
  static final RegExp _listItem = RegExp(r'^(\s*)([-*+]|\d{1,9}[.)])\s+(.*)$');
  static final RegExp _tableSeparator = RegExp(
    r'^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$',
  );

  List<MarkdownBlock> scan() {
    while (_index < _lines.length) {
      final line = _lines[_index];
      if (line.trim().isEmpty) {
        _index++;
      } else if (MarkdownBlockParser.fenceOpening.firstMatch(line)
          case final match?) {
        _scanCode(match);
      } else if (_heading.firstMatch(line) case final match?) {
        _blocks.add(
          HeadingBlock(
            level: match.group(1)!.length,
            inlines: MarkdownInlineParser.parse(match.group(2)!),
          ),
        );
        _index++;
      } else if (_isTableStart(_index)) {
        _scanTable();
      } else if (_rule.hasMatch(line)) {
        _blocks.add(const RuleBlock());
        _index++;
      } else if (_quote.hasMatch(line)) {
        _scanQuote();
      } else if (_listItem.hasMatch(line)) {
        _scanList();
      } else {
        _scanParagraph();
      }
    }
    return List.unmodifiable(_blocks);
  }

  void _scanCode(RegExpMatch opening) {
    final fence = opening.group(1)!;
    final language = opening.group(2) ?? '';
    final code = <String>[];
    _index++;
    while (_index < _lines.length) {
      final line = _lines[_index];
      if (MarkdownBlockParser.closesFence(line, fence)) {
        _index++;
        _blocks.add(
          CodeBlock(language: language, code: code.join('\n'), isClosed: true),
        );
        return;
      }
      code.add(line);
      _index++;
    }
    _blocks.add(
      CodeBlock(language: language, code: code.join('\n'), isClosed: false),
    );
  }

  bool _isTableStart(int index) =>
      _lines[index].contains('|') &&
      index + 1 < _lines.length &&
      _tableSeparator.hasMatch(_lines[index + 1]);

  void _scanTable() {
    final header = _splitRow(_lines[_index]);
    final alignments = _splitRow(_lines[_index + 1]).map(_alignmentOf).toList();
    _index += 2;
    final rows = <List<List<MarkdownInline>>>[];
    while (_index < _lines.length &&
        _lines[_index].trim().isNotEmpty &&
        _lines[_index].contains('|')) {
      final cells = _splitRow(_lines[_index]);
      rows.add([
        for (var column = 0; column < header.length; column++)
          MarkdownInlineParser.parse(
            column < cells.length ? cells[column] : '',
          ),
      ]);
      _index++;
    }
    _blocks.add(
      TableBlock(
        header: [for (final cell in header) MarkdownInlineParser.parse(cell)],
        alignments: [
          for (var column = 0; column < header.length; column++)
            column < alignments.length
                ? alignments[column]
                : TableAlignment.start,
        ],
        rows: rows,
      ),
    );
  }

  static List<String> _splitRow(String line) {
    var content = line.trim();
    if (content.startsWith('|')) content = content.substring(1);
    if (content.endsWith('|')) {
      content = content.substring(0, content.length - 1);
    }
    return content.split('|').map((cell) => cell.trim()).toList();
  }

  static TableAlignment _alignmentOf(String separator) {
    final left = separator.startsWith(':');
    final right = separator.endsWith(':');
    if (left && right) return TableAlignment.center;
    if (right) return TableAlignment.end;
    return TableAlignment.start;
  }

  void _scanQuote() {
    final lines = <String>[];
    while (_index < _lines.length) {
      final match = _quote.firstMatch(_lines[_index]);
      if (match == null) break;
      lines.add(match.group(1)!.trim());
      _index++;
    }
    _blocks.add(QuoteBlock(MarkdownInlineParser.parse(lines.join(' '))));
  }

  void _scanList() {
    final items = <ListItem>[];
    while (_index < _lines.length) {
      final line = _lines[_index];
      if (line.trim().isEmpty) break;
      final match = _listItem.firstMatch(line);
      if (match != null && !_rule.hasMatch(line)) {
        items.add(_listItemOf(match));
      } else if (items.isNotEmpty && line.startsWith('  ')) {
        final previous = items.removeLast();
        items.add(
          ListItem(
            depth: previous.depth,
            marker: previous.marker,
            inlines: [
              ...previous.inlines,
              const TextInline(' '),
              ...MarkdownInlineParser.parse(line.trim()),
            ],
          ),
        );
      } else {
        break;
      }
      _index++;
    }
    _blocks.add(ListBlock(List.unmodifiable(items)));
  }

  static ListItem _listItemOf(RegExpMatch match) {
    final depth = (match.group(1)!.replaceAll('\t', '  ').length ~/ 2).clamp(
      0,
      3,
    );
    final rawMarker = match.group(2)!;
    final isOrdered = RegExp(r'^\d').hasMatch(rawMarker);
    return ListItem(
      depth: depth,
      marker: isOrdered
          ? '${rawMarker.substring(0, rawMarker.length - 1)}.'
          : (depth == 0 ? '•' : '◦'),
      inlines: MarkdownInlineParser.parse(match.group(3)!),
    );
  }

  void _scanParagraph() {
    final lines = <String>[];
    while (_index < _lines.length) {
      final line = _lines[_index];
      if (line.trim().isEmpty || (lines.isNotEmpty && _startsBlock(_index))) {
        break;
      }
      lines.add(line.trim());
      _index++;
    }
    _blocks.add(ParagraphBlock(MarkdownInlineParser.parse(lines.join(' '))));
  }

  bool _startsBlock(int index) {
    final line = _lines[index];
    return MarkdownBlockParser.fenceOpening.hasMatch(line) ||
        _heading.hasMatch(line) ||
        _quote.hasMatch(line) ||
        _listItem.hasMatch(line) ||
        _rule.hasMatch(line) ||
        _isTableStart(index);
  }
}
