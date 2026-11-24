import 'package:flutter/foundation.dart';

@immutable
class GroundingSource {
  const GroundingSource({required this.title, required this.uri});

  final String title;
  final Uri uri;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroundingSource && title == other.title && uri == other.uri;

  @override
  int get hashCode => Object.hash(title, uri);
}

@immutable
class SearchGrounding {
  const SearchGrounding({
    this.sources = const [],
    this.searchQueries = const [],
    this.renderedContent,
  });

  final List<GroundingSource> sources;
  final List<String> searchQueries;
  final String? renderedContent;

  bool get hasSearchSuggestions => renderedContent?.isNotEmpty ?? false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchGrounding &&
          listEquals(sources, other.sources) &&
          listEquals(searchQueries, other.searchQueries) &&
          renderedContent == other.renderedContent;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(sources),
    Object.hashAll(searchQueries),
    renderedContent,
  );
}
