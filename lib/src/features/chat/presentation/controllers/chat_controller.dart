import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:llm_stream_ui/src/core/markdown/incremental_markdown_document.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/chat_message.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_event.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_failure.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/response_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/search_grounding.dart';
import 'package:llm_stream_ui/src/features/chat/data/services/chat_service.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/controllers/streaming_message_controller.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/state/chat_state.dart';

class ChatController extends ValueNotifier<ChatState> {
  ChatController(this._service) : super(const ChatState());

  final ChatService _service;
  final Map<int, StreamingMessageController> _streams = {};
  final StringBuffer _naiveBuffer = StringBuffer();
  StreamSubscription<CompletionEvent>? _subscription;
  SearchGrounding? _grounding;
  int _nextId = 0;
  int? _activeMessageId;
  bool _isDisposed = false;

  int? get activeMessageId => _activeMessageId;

  ValueListenable<MarkdownSnapshot>? snapshotFor(int messageId) =>
      _streams[messageId];

  bool isAvailable(ResponseSource source) => _service.isAvailable(source);

  void changeStrategy(RenderingStrategy strategy) {
    if (value.isStreaming) return;
    _emit(value.copyWith(strategy: strategy));
  }

  void changeSource(ResponseSource source) {
    if (value.isStreaming || !_service.isAvailable(source)) return;
    _emit(value.copyWith(source: source));
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
    _grounding = null;

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
        failure: null,
      ),
    );

    final onText = streaming?.add ?? _appendNaive;
    _subscription = _service
        .streamCompletion(prompt, source: value.source)
        .listen(
          (event) => switch (event) {
            TextDelta(:final text) => onText(text),
            GroundingReceived(:final grounding) => _grounding = grounding,
          },
          onError: (Object error) => _finish(failure: _failureOf(error)),
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

  static CompletionFailure _failureOf(Object error) =>
      error is CompletionFailure
      ? error
      : const CompletionFailure(CompletionFailureReason.interrupted);

  void _finish({CompletionFailure? failure}) {
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
            message.id == messageId
                ? message.copyWith(text: text, grounding: _grounding)
                : message,
        ],
        status: ChatStatus.idle,
        failure: failure,
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
