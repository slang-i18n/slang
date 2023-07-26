/// A response from the GPT API.
class GptResponse {
  /// The raw prompt answer.
  final String rawMessage;

  /// The parsed prompt answer.
  final Map<String, dynamic> jsonMessage;

  /// The number of input tokens.
  final int promptTokens;

  /// The number of output tokens.
  final int completionTokens;

  /// The total number of tokens.
  final int totalTokens;

  const GptResponse({
    required this.rawMessage,
    required this.jsonMessage,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });
}
