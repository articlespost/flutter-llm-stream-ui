import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/markdown/incremental_markdown_document.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_node.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/markdown_block_view.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/markdown_style.dart';
import 'package:llm_stream_ui/src/core/markdown/widgets/streaming_cursor.dart';

class StreamingMarkdownView extends StatefulWidget {
  const StreamingMarkdownView({super.key, required this.snapshot});

  final ValueListenable<MarkdownSnapshot> snapshot;

  @override
  State<StreamingMarkdownView> createState() => _StreamingMarkdownViewState();
}

class _StreamingMarkdownViewState extends State<StreamingMarkdownView> {
  final List<Widget> _frozenWidgets = [];
  ThemeData? _theme;
  late MarkdownStyle _style;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    if (identical(theme, _theme)) return;
    _theme = theme;
    _style = MarkdownStyle.of(theme);
    _frozenWidgets.clear();
  }

  @override
  void didUpdateWidget(StreamingMarkdownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.snapshot, widget.snapshot)) {
      _frozenWidgets.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MarkdownSnapshot>(
      valueListenable: widget.snapshot,
      builder: (context, snapshot, _) {
        _syncFrozenWidgets(snapshot.frozenBlocks);
        final hasTail = snapshot.tailBlocks.isNotEmpty || !snapshot.isComplete;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._frozenWidgets,
            if (hasTail)
              RepaintBoundary(
                key: const ValueKey('markdown-tail'),
                child: _TailView(
                  blocks: snapshot.tailBlocks,
                  style: _style,
                  showCursor: !snapshot.isComplete,
                ),
              ),
          ],
        );
      },
    );
  }

  void _syncFrozenWidgets(List<MarkdownBlock> blocks) {
    for (var index = _frozenWidgets.length; index < blocks.length; index++) {
      _frozenWidgets.add(
        RepaintBoundary(
          key: ValueKey('markdown-frozen-$index'),
          child: Padding(
            padding: EdgeInsets.only(bottom: _style.blockSpacing),
            child: MarkdownBlockView(block: blocks[index], style: _style),
          ),
        ),
      );
    }
  }
}

class _TailView extends StatelessWidget {
  const _TailView({
    required this.blocks,
    required this.style,
    required this.showCursor,
  });

  final List<MarkdownBlock> blocks;
  final MarkdownStyle style;
  final bool showCursor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks)
          Padding(
            padding: EdgeInsets.only(bottom: style.blockSpacing),
            child: MarkdownBlockView(block: block, style: style),
          ),
        if (showCursor)
          const Align(
            alignment: Alignment.centerLeft,
            child: StreamingCursor(),
          ),
      ],
    );
  }
}
