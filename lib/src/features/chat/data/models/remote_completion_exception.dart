class RemoteCompletionException implements Exception {
  const RemoteCompletionException(this.code);

  factory RemoteCompletionException.fromJson(Map<String, Object?> json) =>
      RemoteCompletionException(
        json['code'] is String ? json['code']! as String : 'unknown',
      );

  static const String interrupted = 'interrupted';

  final String code;

  @override
  String toString() => 'RemoteCompletionException($code)';
}
