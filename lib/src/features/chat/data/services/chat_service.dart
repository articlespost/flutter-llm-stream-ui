import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_event.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/response_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/repositories/i_chat_repository.dart';

class ChatService {
  const ChatService(this._repository);

  static const int maxPromptLength = 2000;

  final IChatRepository _repository;

  bool isValidPrompt(String prompt) {
    final trimmed = prompt.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxPromptLength;
  }

  bool isAvailable(ResponseSource source) => _repository.isAvailable(source);

  Stream<CompletionEvent> streamCompletion(
    String prompt, {
    ResponseSource source = ResponseSource.simulated,
  }) => _repository.streamCompletion(prompt.trim(), source: source);
}
