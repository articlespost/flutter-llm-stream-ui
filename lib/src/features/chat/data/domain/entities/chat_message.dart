import 'package:flutter/foundation.dart';

enum MessageRole { user, assistant }

@immutable
class ChatMessage {
  const ChatMessage({required this.id, required this.role, required this.text});

  final int id;
  final MessageRole role;
  final String text;

  ChatMessage copyWith({String? text}) =>
      ChatMessage(id: id, role: role, text: text ?? this.text);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          id == other.id &&
          role == other.role &&
          text == other.text;

  @override
  int get hashCode => Object.hash(id, role, text);
}
