enum GptProvider {
  openai,
}

// ignore_for_file: constant_identifier_names
enum GptModel {
  gpt3_5_4k('gpt-3.5-turbo', GptProvider.openai,
      defaultInputLength: 2000,
      costPer1kInputToken: 0.0005,
      costPer1kOutputToken: 0.0015),
  gpt3_5_16k('gpt-3.5-turbo-16k', GptProvider.openai,
      defaultInputLength: 8000,
      costPer1kInputToken: 0.003,
      costPer1kOutputToken: 0.004),
  gpt4_8k('gpt-4', GptProvider.openai,
      defaultInputLength: 4000,
      costPer1kInputToken: 0.03,
      costPer1kOutputToken: 0.06),
  gpt4_turbo('gpt-4-turbo', GptProvider.openai,
      defaultInputLength: 64000,
      costPer1kInputToken: 0.01,
      costPer1kOutputToken: 0.03),
  gpt4o('gpt-4o', GptProvider.openai,
      defaultInputLength: 128000,
      costPer1kInputToken: 0.005,
      costPer1kOutputToken: 0.015),
  gpt4o_mini('gpt-4o-mini', GptProvider.openai,
      defaultInputLength: 128000,
      costPer1kInputToken: 0.00015,
      costPer1kOutputToken: 0.0006),
  gpt4_1('gpt-4.1', GptProvider.openai,
      defaultInputLength: 1047576,
      costPer1kInputToken: 0.002,
      costPer1kOutputToken: 0.008),
  gpt5('gpt-5', GptProvider.openai,
      defaultInputLength: 400000,
      costPer1kInputToken: 0.00125,
      costPer1kOutputToken: 0.01),
  gpt5_mini('gpt-5-mini', GptProvider.openai,
      defaultInputLength: 400000,
      costPer1kInputToken: 0.00025,
      costPer1kOutputToken: 0.002);

  const GptModel(
    this.id,
    this.provider, {
    required this.defaultInputLength,
    required this.costPer1kInputToken,
    required this.costPer1kOutputToken,
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
  final double costPer1kInputToken;

  double get costPerInputToken => costPer1kInputToken / 1000;

  /// The cost per output token in USD.
  final double costPer1kOutputToken;

  double get costPerOutputToken => costPer1kOutputToken / 1000;
}
