import 'package:flutter/foundation.dart';
import 'package:llm_stream_ui/src/core/markdown/incremental_markdown_document.dart';
import 'package:llm_stream_ui/src/core/stream/frame_batcher.dart';

class StreamingMessageController extends ValueNotifier<MarkdownSnapshot> {
  StreamingMessageController() : super(MarkdownSnapshot.empty);

  factory StreamingMessageController.completed(String text) =>
      StreamingMessageController()
        .._text.write(text)
        .._document.append(text)
        ..complete();

  final IncrementalMarkdownDocument _document = IncrementalMarkdownDocument();
  final StringBuffer _text = StringBuffer();
  late final FrameBatcher _batcher = FrameBatcher(onFlush: _apply);

  String get text => _text.toString();

  void add(String chunk) {
    _text.write(chunk);
    _batcher.add(chunk);
  }

  void complete() {
    _batcher.flush();
    _document.complete();
    value = _document.snapshot;
  }

  void _apply(String batch) {
    _document.append(batch);
    value = _document.snapshot;
  }

  @override
  void dispose() {
    _batcher.dispose();
    super.dispose();
  }
}
