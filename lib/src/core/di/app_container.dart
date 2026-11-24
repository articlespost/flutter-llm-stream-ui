import 'package:llm_stream_ui/src/core/network/streaming_http_client.dart';
import 'package:llm_stream_ui/src/features/chat/data/datasource/gemini_proxy_data_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/datasource/llm_stream_data_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:llm_stream_ui/src/features/chat/data/services/chat_service.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/controllers/chat_controller.dart';

class AppContainer {
  AppContainer({
    LlmStreamDataSource dataSource = const LlmStreamDataSource(),
    Uri? geminiProxyUrl,
  }) : _chatService = ChatService(
         ChatRepositoryImpl(
           dataSource,
           geminiDataSource: geminiProxyUrl == null
               ? null
               : GeminiProxyDataSource(
                   StreamingHttpClient(),
                   baseUrl: geminiProxyUrl,
                 ),
         ),
       );

  final ChatService _chatService;

  ChatController createChatController() => ChatController(_chatService);
}
