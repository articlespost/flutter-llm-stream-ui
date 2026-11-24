import 'package:llm_stream_ui/src/core/markdown/markdown_node.dart';

typedef _InlineMatch = ({MarkdownInline node, int end});

abstract final class MarkdownInlineParser {
  static List<MarkdownInline> parse(String source) =>
      _InlineScanner(source).scan();
}

class _InlineScanner {
  _InlineScanner(this._source);

  final String _source;
  final StringBuffer _text = StringBuffer();
  final List<MarkdownInline> _nodes = [];

  static final RegExp _wordCharacter = RegExp(r'[\p{L}\p{N}]', unicode: true);

  List<MarkdownInline> scan() {
    var index = 0;
    while (index < _source.length) {
      final match = _matchAt(index);
      if (match == null) {
        _text.write(_source[index]);
        index++;
        continue;
      }
      _flushText();
      _nodes.add(match.node);
      index = match.end;
    }
    _flushText();
    return List.unmodifiable(_nodes);
  }

  _InlineMatch? _matchAt(int index) => switch (_source[index]) {
    '`' => _code(index),
    '*' || '_' => _emphasis(index),
    '~' => _delimited(index, '~~', StrikethroughInline.new),
    '[' => _link(index),
    _ => null,
  };

  _InlineMatch? _code(int index) {
    final close = _source.indexOf('`', index + 1);
    if (close <= index + 1) return null;
    return (
      node: CodeInline(_source.substring(index + 1, close)),
      end: close + 1,
    );
  }

  _InlineMatch? _emphasis(int index) {
    final marker = _source[index];
    if (marker == '_' && index > 0 && _isWordCharacter(_source[index - 1])) {
      return null;
    }
    if (_source.startsWith('$marker$marker', index)) {
      return _delimited(index, '$marker$marker', StrongInline.new);
    }
    return _delimited(index, marker, EmphasisInline.new);
  }

  _InlineMatch? _delimited(
    int index,
    String delimiter,
    MarkdownInline Function(List<MarkdownInline> children) build,
  ) {
    if (!_source.startsWith(delimiter, index)) return null;
    final start = index + delimiter.length;
    var close = _source.indexOf(delimiter, start);
    if (close <= start) return null;
    while (close + delimiter.length < _source.length &&
        _source[close + delimiter.length] == delimiter[0]) {
      close++;
    }
    final inner = _source.substring(start, close);
    if (inner.trim() != inner) return null;
    return (
      node: build(MarkdownInlineParser.parse(inner)),
      end: close + delimiter.length,
    );
  }

  _InlineMatch? _link(int index) {
    final closeBracket = _source.indexOf('](', index + 1);
    if (closeBracket == -1) return null;
    final closeParen = _source.indexOf(')', closeBracket + 2);
    if (closeParen == -1) return null;
    final label = _source.substring(index + 1, closeBracket);
    final url = _source.substring(closeBracket + 2, closeParen).trim();
    if (label.isEmpty || url.isEmpty || url.contains(' ')) return null;
    return (
      node: LinkInline(children: MarkdownInlineParser.parse(label), url: url),
      end: closeParen + 1,
    );
  }

  bool _isWordCharacter(String character) => _wordCharacter.hasMatch(character);

  void _flushText() {
    if (_text.isEmpty) return;
    _nodes.add(TextInline(_text.toString()));
    _text.clear();
  }
}
