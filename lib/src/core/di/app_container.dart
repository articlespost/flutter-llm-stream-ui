import 'package:llm_stream_ui/src/features/chat/data/datasource/llm_stream_data_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:llm_stream_ui/src/features/chat/data/services/chat_service.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/controllers/chat_controller.dart';

class AppContainer {
  AppContainer({LlmStreamDataSource dataSource = const LlmStreamDataSource()})
    : _chatService = ChatService(ChatRepositoryImpl(dataSource));

  final ChatService _chatService;

  ChatController createChatController() => ChatController(_chatService);
}
