import 'dart:convert';

sealed class GeminiEvent {
  const GeminiEvent();
}

final class GeminiText extends GeminiEvent {
  const GeminiText(this.text);

  final String text;
}

final class GeminiBlocked extends GeminiEvent {
  const GeminiBlocked(this.reason);

  final String reason;
}

class GroundingAccumulator {
  final List<Map<String, String>> _sources = [];
  final Set<String> _sourceUris = {};
  final List<String> _searchQueries = [];
  String? _renderedContent;

  bool get isEmpty =>
      _sources.isEmpty && _searchQueries.isEmpty && _renderedContent == null;

  void add(Map<String, Object?> metadata) {
    if (metadata['groundingChunks'] case final List<Object?> chunks) {
      for (final chunk in chunks) {
        if (chunk case {'web': final Map<String, Object?> web}) {
          final uri = web['uri'];
          if (uri is! String || uri.isEmpty || !_sourceUris.add(uri)) continue;
          final title = web['title'];
          _sources.add({
            'uri': uri,
            'title': title is String && title.isNotEmpty ? title : uri,
          });
        }
      }
    }
    if (metadata['webSearchQueries'] case final List<Object?> queries) {
      for (final query in queries) {
        if (query is String && !_searchQueries.contains(query)) {
          _searchQueries.add(query);
        }
      }
    }
    if (metadata['searchEntryPoint']
        case {'renderedContent': final String renderedContent}
        when renderedContent.isNotEmpty) {
      _renderedContent = renderedContent;
    }
  }

  Map<String, Object?> toJson() => {
    'sources': _sources,
    'searchQueries': _searchQueries,
    'renderedContent': _renderedContent,
  };
}

class GeminiStreamParser {
  static const Set<String> _blockingFinishReasons = {
    'SAFETY',
    'RECITATION',
    'BLOCKLIST',
    'PROHIBITED_CONTENT',
    'SPII',
  };

  final GroundingAccumulator grounding = GroundingAccumulator();

  List<GeminiEvent> parse(String data) {
    final Object? json;
    try {
      json = jsonDecode(data);
    } on FormatException {
      return const [];
    }
    if (json is! Map<String, Object?>) return const [];

    if (json case {'promptFeedback': {'blockReason': final String reason}}) {
      return [GeminiBlocked(reason)];
    }

    final events = <GeminiEvent>[];
    if (json case {'candidates': [final Map<String, Object?> candidate, ...]}) {
      if (candidate case {'content': {'parts': final List<Object?> parts}}) {
        for (final part in parts) {
          if (part case {'text': final String text}
              when text.isNotEmpty && part['thought'] != true) {
            events.add(GeminiText(text));
          }
        }
      }
      if (candidate['groundingMetadata'] case final Map<String, Object?> meta) {
        grounding.add(meta);
      }
      if (candidate['finishReason'] case final String reason
          when _blockingFinishReasons.contains(reason)) {
        events.add(GeminiBlocked(reason));
      }
    }
    return events;
  }
}
