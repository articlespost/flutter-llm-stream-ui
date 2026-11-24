import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:llm_stream_ui/src/core/markdown/incremental_markdown_document.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/chat_message.dart';
import 'package:llm_stream_ui/src/features/chat/data/services/chat_service.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/controllers/streaming_message_controller.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/state/chat_state.dart';

class ChatController extends ValueNotifier<ChatState> {
  ChatController(this._service) : super(const ChatState());

  final ChatService _service;
  final Map<int, StreamingMessageController> _streams = {};
  final StringBuffer _naiveBuffer = StringBuffer();
  StreamSubscription<String>? _subscription;
  int _nextId = 0;
  int? _activeMessageId;
  bool _isDisposed = false;

  int? get activeMessageId => _activeMessageId;

  ValueListenable<MarkdownSnapshot>? snapshotFor(int messageId) =>
      _streams[messageId];

  void changeStrategy(RenderingStrategy strategy) {
    if (value.isStreaming) return;
    _emit(value.copyWith(strategy: strategy));
  }

  void send(String prompt) {
    if (value.isStreaming || !_service.isValidPrompt(prompt)) return;

    final userMessage = ChatMessage(
      id: _nextId++,
      role: MessageRole.user,
      text: prompt.trim(),
    );
    final assistantId = _nextId++;
    _activeMessageId = assistantId;
    _naiveBuffer.clear();

    final isOptimized = value.strategy == RenderingStrategy.optimized;
    final streaming = isOptimized ? StreamingMessageController() : null;
    if (streaming != null) _streams[assistantId] = streaming;

    _emit(
      value.copyWith(
        messages: [
          ...value.messages,
          userMessage,
          ChatMessage(id: assistantId, role: MessageRole.assistant, text: ''),
        ],
        status: ChatStatus.streaming,
        hasError: false,
      ),
    );

    _subscription = _service
        .streamCompletion(prompt)
        .listen(
          streaming?.add ?? _appendNaive,
          onError: (Object _) => _finish(hasError: true),
          onDone: _finish,
          cancelOnError: true,
        );
  }

  Future<void> stop() async {
    final subscription = _subscription;
    if (subscription == null) return;
    _subscription = null;
    await subscription.cancel();
    _finish();
  }

  void _appendNaive(String chunk) {
    _naiveBuffer.write(chunk);
    final messages = [...value.messages];
    messages[messages.length - 1] = messages.last.copyWith(
      text: _naiveBuffer.toString(),
    );
    _emit(value.copyWith(messages: messages));
  }

  void _finish({bool hasError = false}) {
    final messageId = _activeMessageId;
    if (messageId == null) return;
    _activeMessageId = null;
    _subscription = null;

    final streaming = _streams[messageId];
    final String text;
    if (streaming != null) {
      streaming.complete();
      text = streaming.text;
    } else {
      text = _naiveBuffer.toString();
      _streams[messageId] = StreamingMessageController.completed(text);
    }

    _emit(
      value.copyWith(
        messages: [
          for (final message in value.messages)
            message.id == messageId ? message.copyWith(text: text) : message,
        ],
        status: ChatStatus.idle,
        hasError: hasError,
      ),
    );
  }

  void _emit(ChatState state) {
    if (!_isDisposed) value = state;
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_subscription?.cancel());
    for (final streaming in _streams.values) {
      streaming.dispose();
    }
    super.dispose();
  }
}
