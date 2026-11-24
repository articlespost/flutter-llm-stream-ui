import 'package:flutter/foundation.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/search_grounding.dart';

@immutable
sealed class CompletionEvent {
  const CompletionEvent();
}

final class TextDelta extends CompletionEvent {
  const TextDelta(this.text);

  final String text;
}

final class GroundingReceived extends CompletionEvent {
  const GroundingReceived(this.grounding);

  final SearchGrounding grounding;
}
