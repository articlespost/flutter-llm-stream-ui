import 'package:flutter/foundation.dart';

enum CompletionFailureReason {
  sourceUnavailable,
  quotaExceeded,
  rateLimited,
  permissionDenied,
  modelNotFound,
  blocked,
  interrupted,
}

@immutable
class CompletionFailure implements Exception {
  const CompletionFailure(this.reason);

  final CompletionFailureReason reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletionFailure && reason == other.reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'CompletionFailure(${reason.name})';
}
