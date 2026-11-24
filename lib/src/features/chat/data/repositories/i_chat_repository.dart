import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_event.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/response_source.dart';

abstract class IChatRepository {
  bool isAvailable(ResponseSource source);

  Stream<CompletionEvent> streamCompletion(
    String prompt, {
    required ResponseSource source,
  });
}
