import 'package:flutter/foundation.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/chat_message.dart';

enum RenderingStrategy { naive, optimized }

enum ChatStatus { idle, streaming }

@immutable
class ChatState {
  const ChatState({
    this.messages = const [],
    this.status = ChatStatus.idle,
    this.strategy = RenderingStrategy.optimized,
    this.hasError = false,
  });

  final List<ChatMessage> messages;
  final ChatStatus status;
  final RenderingStrategy strategy;
  final bool hasError;

  bool get isStreaming => status == ChatStatus.streaming;

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatStatus? status,
    RenderingStrategy? strategy,
    bool? hasError,
  }) => ChatState(
    messages: messages ?? this.messages,
    status: status ?? this.status,
    strategy: strategy ?? this.strategy,
    hasError: hasError ?? this.hasError,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatState &&
          listEquals(messages, other.messages) &&
          status == other.status &&
          strategy == other.strategy &&
          hasError == other.hasError;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(messages), status, strategy, hasError);
}
