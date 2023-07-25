class GptResponse {
  final String rawMessage;
  final Map<String, dynamic> jsonMessage;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const GptResponse({
    required this.rawMessage,
    required this.jsonMessage,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });
}
