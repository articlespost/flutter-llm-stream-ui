import 'package:llm_stream_ui/src/features/chat/data/domain/entities/completion_event.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/search_grounding.dart';

sealed class CompletionEventModel {
  const CompletionEventModel();

  CompletionEvent toEntity();
}

final class TextDeltaModel extends CompletionEventModel {
  const TextDeltaModel(this.text);

  factory TextDeltaModel.fromJson(Map<String, Object?> json) =>
      TextDeltaModel(json['text'] is String ? json['text']! as String : '');

  final String text;

  @override
  CompletionEvent toEntity() => TextDelta(text);
}

final class GroundingModel extends CompletionEventModel {
  const GroundingModel({
    required this.sources,
    required this.searchQueries,
    this.renderedContent,
  });

  factory GroundingModel.fromJson(Map<String, Object?> json) {
    final sources = <GroundingSourceModel>[];
    if (json['sources'] case final List<Object?> items) {
      for (final item in items) {
        if (item case {'uri': final String uri, 'title': final String title}) {
          final parsed = Uri.tryParse(uri);
          if (parsed != null && parsed.scheme == 'https') {
            sources.add(GroundingSourceModel(title: title, uri: parsed));
          }
        }
      }
    }
    final queries = <String>[
      if (json['searchQueries'] case final List<Object?> items)
        for (final item in items)
          if (item is String) item,
    ];
    final renderedContent = json['renderedContent'];
    return GroundingModel(
      sources: sources,
      searchQueries: queries,
      renderedContent: renderedContent is String && renderedContent.isNotEmpty
          ? renderedContent
          : null,
    );
  }

  final List<GroundingSourceModel> sources;
  final List<String> searchQueries;
  final String? renderedContent;

  @override
  CompletionEvent toEntity() => GroundingReceived(
    SearchGrounding(
      sources: [
        for (final source in sources)
          GroundingSource(title: source.title, uri: source.uri),
      ],
      searchQueries: List.unmodifiable(searchQueries),
      renderedContent: renderedContent,
    ),
  );
}

class GroundingSourceModel {
  const GroundingSourceModel({required this.title, required this.uri});

  final String title;
  final Uri uri;
}
