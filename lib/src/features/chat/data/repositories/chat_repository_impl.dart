import 'package:llm_stream_ui/src/features/chat/data/datasource/llm_stream_data_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/models/completion_request_model.dart';
import 'package:llm_stream_ui/src/features/chat/data/repositories/i_chat_repository.dart';

class ChatRepositoryImpl implements IChatRepository {
  const ChatRepositoryImpl(this._dataSource);

  final LlmStreamDataSource _dataSource;

  @override
  Stream<String> streamCompletion(String prompt) =>
      _dataSource.streamCompletion(CompletionRequestModel(prompt: prompt));
}
