enum GptProvider {
  openai,
}

enum GptModel {
  gpt3_5_4k('gpt-3.5-turbo', 5320, GptProvider.openai),
  gpt3_5_16k('gpt-3.5-turbo-16k', 21280, GptProvider.openai),
  ;

  const GptModel(this.id, this.defaultInputLength, this.provider);

  final String id;

  /// Each model has a limited context until this model starts to "forget".
  ///
  /// The default input length is calculated as follows:
  /// 1 token = 4 characters (English)
  /// input context = 1 / 3 of the model's context (Assuming 2x output context)
  /// Therefore, input_length = 1.33 * model_context
  final int defaultInputLength;

  final GptProvider provider;
}
