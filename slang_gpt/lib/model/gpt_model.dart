enum GptProvider {
  openai,
}

enum GptModel {
  gpt3_5_4k('gpt-3.5-turbo', GptProvider.openai,
      defaultInputLength: 2000,
      costPerInputToken: 0.0000015,
      costPerOutputToken: 0.000002),
  gpt3_5_16k('gpt-3.5-turbo-16k', GptProvider.openai,
      defaultInputLength: 8000,
      costPerInputToken: 0.000003,
      costPerOutputToken: 0.000004),
  gpt4_8k('gpt-4', GptProvider.openai,
      defaultInputLength: 4000,
      costPerInputToken: 0.00003,
      costPerOutputToken: 0.00006),
  ;

  const GptModel(
    this.id,
    this.provider, {
    required this.defaultInputLength,
    required this.costPerInputToken,
    required this.costPerOutputToken,
  });

  /// The id of this model.
  /// Will be sent to the GPT API.
  final String id;

  /// The provider of this model.
  final GptProvider provider;

  /// Each model has a limited context until this model starts to "forget".
  ///
  /// The default input length is calculated as follows:
  /// 1 token = 4 characters (English)
  /// input context = 1 / 3 of the model's context (Assuming 2x output context)
  /// Therefore, input_length = 1.33 * model_context
  final int defaultInputLength;

  /// The cost per input token in USD.
  final double costPerInputToken;

  /// The cost per output token in USD.
  final double costPerOutputToken;
}
