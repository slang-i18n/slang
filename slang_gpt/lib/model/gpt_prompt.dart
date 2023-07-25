class GptPrompt {
  /// Contains the general instruction and the app description.
  final String system;

  /// Contains the base translations.
  final String user;

  /// Contains the JSON representation of the prompt. (Debugging)
  final Map<String, dynamic> userJSON;

  const GptPrompt({
    required this.system,
    required this.user,
    required this.userJSON,
  });
}
