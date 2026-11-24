class CompletionRequestModel {
  const CompletionRequestModel({required this.prompt});

  final String prompt;

  Map<String, Object> toJson() => {'prompt': prompt};
}
