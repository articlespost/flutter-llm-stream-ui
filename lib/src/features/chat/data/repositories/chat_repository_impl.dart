import 'dart:async';
import 'dart:io';

import 'package:llm_stream_ui/src/core/network/streaming_http_client.dart';
import 'package:llm_stream_ui/src/features/chat/data/datasource/gemini_proxy_data_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/datasource/llm_stream_data_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_event.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_failure.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/response_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/models/completion_request_model.dart';
import 'package:llm_stream_ui/src/features/chat/data/models/remote_completion_exception.dart';
import 'package:llm_stream_ui/src/features/chat/data/repositories/i_chat_repository.dart';

class ChatRepositoryImpl implements IChatRepository {
  const ChatRepositoryImpl(this._simulatedDataSource, {this._geminiDataSource});

  final LlmStreamDataSource _simulatedDataSource;
  final GeminiProxyDataSource? _geminiDataSource;

  @override
  bool isAvailable(ResponseSource source) => switch (source) {
    ResponseSource.simulated => true,
    ResponseSource.gemini => _geminiDataSource != null,
  };

  @override
  Stream<CompletionEvent> streamCompletion(
    String prompt, {
    required ResponseSource source,
  }) {
    final request = CompletionRequestModel(prompt: prompt);
    final geminiDataSource = _geminiDataSource;
    return switch (source) {
      ResponseSource.simulated =>
        _simulatedDataSource.streamCompletion(request).map(TextDelta.new),
      ResponseSource.gemini when geminiDataSource != null =>
        geminiDataSource
            .streamCompletion(request)
            .map((model) => model.toEntity())
            .transform(_failureMapper),
      ResponseSource.gemini => Stream.error(
        const CompletionFailure(CompletionFailureReason.sourceUnavailable),
      ),
    };
  }

  static final StreamTransformer<CompletionEvent, CompletionEvent>
  _failureMapper = StreamTransformer.fromHandlers(
    handleError: (error, stackTrace, sink) =>
        sink.addError(_failureOf(error), stackTrace),
  );

  static CompletionFailure _failureOf(Object error) =>
      CompletionFailure(switch (error) {
        CompletionFailure(:final reason) => reason,
        RemoteCompletionException(code: 'quota_exceeded') ||
        HttpStatusException(
          code: 'quota_exceeded',
        ) => CompletionFailureReason.quotaExceeded,
        RemoteCompletionException(code: 'rate_limited' || 'busy') ||
        HttpStatusException(
          code: 'rate_limited' || 'busy',
        ) => CompletionFailureReason.rateLimited,
        RemoteCompletionException(code: 'permission_denied') =>
          CompletionFailureReason.permissionDenied,
        RemoteCompletionException(code: 'model_not_found') =>
          CompletionFailureReason.modelNotFound,
        RemoteCompletionException(code: 'blocked') =>
          CompletionFailureReason.blocked,
        SocketException() ||
        TimeoutException() ||
        HttpStatusException() ||
        RemoteCompletionException(
          code: 'unavailable',
        ) => CompletionFailureReason.sourceUnavailable,
        _ => CompletionFailureReason.interrupted,
      });
}
