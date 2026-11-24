import 'package:flutter/scheduler.dart';

class FrameBatcher {
  FrameBatcher({required this.onFlush});

  final void Function(String batch) onFlush;
  final StringBuffer _buffer = StringBuffer();
  bool _isScheduled = false;
  bool _isDisposed = false;

  void add(String chunk) {
    if (_isDisposed || chunk.isEmpty) return;
    _buffer.write(chunk);
    if (_isScheduled) return;
    _isScheduled = true;
    SchedulerBinding.instance
      ..scheduleFrameCallback(_onFrame)
      ..scheduleFrame();
  }

  void flush() {
    if (_isDisposed || _buffer.isEmpty) return;
    final batch = _buffer.toString();
    _buffer.clear();
    onFlush(batch);
  }

  void dispose() {
    _isDisposed = true;
    _buffer.clear();
  }

  void _onFrame(Duration _) {
    _isScheduled = false;
    flush();
  }
}
