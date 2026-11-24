import 'dart:convert';

import 'package:llm_stream_ui/src/core/network/streaming_http_client.dart';
import 'package:llm_stream_ui/src/features/chat/data/models/completion_event_model.dart';
import 'package:llm_stream_ui/src/features/chat/data/models/completion_request_model.dart';
import 'package:llm_stream_ui/src/features/chat/data/models/remote_completion_exception.dart';

class GeminiProxyDataSource {
  const GeminiProxyDataSource(this._client, {required this.baseUrl});

  static const String streamPath = '/v1/completions:stream';

  final StreamingHttpClient _client;
  final Uri baseUrl;

  Stream<CompletionEventModel> streamCompletion(
    CompletionRequestModel request,
  ) async* {
    final events = _client.postForEvents(
      baseUrl.resolve(streamPath),
      request.toJson(),
    );
    await for (final event in events) {
      switch (event.event) {
        case null || 'message':
          yield TextDeltaModel.fromJson(_decode(event.data));
        case 'grounding':
          yield GroundingModel.fromJson(_decode(event.data));
        case 'error':
          throw RemoteCompletionException.fromJson(_decode(event.data));
        case 'done':
          return;
      }
    }
    throw const RemoteCompletionException(
      RemoteCompletionException.interrupted,
    );
  }

  static Map<String, Object?> _decode(String data) {
    final json = jsonDecode(data);
    return json is Map<String, Object?> ? json : const {};
  }
}
