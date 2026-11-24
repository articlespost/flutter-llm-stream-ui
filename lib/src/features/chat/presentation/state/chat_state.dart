import 'package:flutter/foundation.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/chat_message.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_failure.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/response_source.dart';

enum RenderingStrategy { naive, optimized }

enum ChatStatus { idle, streaming }

@immutable
class ChatState {
  const ChatState({
    this.messages = const [],
    this.status = ChatStatus.idle,
    this.strategy = RenderingStrategy.optimized,
    this.source = ResponseSource.simulated,
    this.failure,
  });

  static const Object _unchanged = Object();

  final List<ChatMessage> messages;
  final ChatStatus status;
  final RenderingStrategy strategy;
  final ResponseSource source;
  final CompletionFailure? failure;

  bool get isStreaming => status == ChatStatus.streaming;

  bool get hasError => failure != null;

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatStatus? status,
    RenderingStrategy? strategy,
    ResponseSource? source,
    Object? failure = _unchanged,
  }) => ChatState(
    messages: messages ?? this.messages,
    status: status ?? this.status,
    strategy: strategy ?? this.strategy,
    source: source ?? this.source,
    failure: identical(failure, _unchanged)
        ? this.failure
        : failure as CompletionFailure?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatState &&
          listEquals(messages, other.messages) &&
          status == other.status &&
          strategy == other.strategy &&
          source == other.source &&
          failure == other.failure;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(messages), status, strategy, source, failure);
}
