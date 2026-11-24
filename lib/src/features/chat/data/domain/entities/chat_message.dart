import 'package:flutter/foundation.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/search_grounding.dart';

enum MessageRole { user, assistant }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.grounding,
  });

  final int id;
  final MessageRole role;
  final String text;
  final SearchGrounding? grounding;

  ChatMessage copyWith({String? text, SearchGrounding? grounding}) =>
      ChatMessage(
        id: id,
        role: role,
        text: text ?? this.text,
        grounding: grounding ?? this.grounding,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          id == other.id &&
          role == other.role &&
          text == other.text &&
          grounding == other.grounding;

  @override
  int get hashCode => Object.hash(id, role, text, grounding);
}
