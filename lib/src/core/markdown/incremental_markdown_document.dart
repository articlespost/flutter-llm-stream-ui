import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_block_parser.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_node.dart';

@immutable
final class MarkdownSnapshot {
  const MarkdownSnapshot({
    required this.frozenBlocks,
    required this.tailBlocks,
    required this.isComplete,
  });

  static const MarkdownSnapshot empty = MarkdownSnapshot(
    frozenBlocks: [],
    tailBlocks: [],
    isComplete: false,
  );

  final List<MarkdownBlock> frozenBlocks;
  final List<MarkdownBlock> tailBlocks;
  final bool isComplete;
}

class IncrementalMarkdownDocument {
  final List<MarkdownBlock> _frozenBlocks = [];
  String _tail = '';
  List<MarkdownBlock> _tailBlocks = const [];
  bool _isComplete = false;

  MarkdownSnapshot get snapshot => MarkdownSnapshot(
    frozenBlocks: UnmodifiableListView(_frozenBlocks),
    tailBlocks: _tailBlocks,
    isComplete: _isComplete,
  );

  void append(String chunk) {
    if (_isComplete || chunk.isEmpty) return;
    final source = '$_tail${chunk.replaceAll('\r', '')}';
    final boundary = _lastStableBoundary(source);
    if (boundary > 0) {
      _frozenBlocks.addAll(
        MarkdownBlockParser.parse(source.substring(0, boundary)),
      );
      _tail = source.substring(boundary);
    } else {
      _tail = source;
    }
    _tailBlocks = MarkdownBlockParser.parse(_tail);
  }

  void complete() {
    if (_isComplete) return;
    _frozenBlocks.addAll(_tailBlocks);
    _tail = '';
    _tailBlocks = const [];
    _isComplete = true;
  }

  static int _lastStableBoundary(String source) {
    var boundary = 0;
    var offset = 0;
    String? openFence;
    while (true) {
      final newline = source.indexOf('\n', offset);
      if (newline == -1) return boundary;
      final line = source.substring(offset, newline);
      final next = newline + 1;
      final fence = openFence;
      if (fence != null) {
        if (MarkdownBlockParser.closesFence(line, fence)) {
          openFence = null;
          boundary = next;
        }
      } else if (MarkdownBlockParser.fenceOpening.firstMatch(line)
          case final match?) {
        openFence = match.group(1);
      } else if (line.trim().isEmpty) {
        boundary = next;
      }
      offset = next;
    }
  }
}
