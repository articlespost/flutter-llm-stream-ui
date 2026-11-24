import 'package:llm_stream_ui/src/features/chat/data/repositories/i_chat_repository.dart';

class ChatService {
  const ChatService(this._repository);

  static const int maxPromptLength = 2000;

  final IChatRepository _repository;

  bool isValidPrompt(String prompt) {
    final trimmed = prompt.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxPromptLength;
  }

  Stream<String> streamCompletion(String prompt) =>
      _repository.streamCompletion(prompt.trim());
}
