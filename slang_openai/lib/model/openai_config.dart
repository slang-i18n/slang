// ignore: implementation_imports
import 'package:slang/src/builder/model/i18n_locale.dart';

/// Represents the openai node in build.yaml
class OpenaiConfig {
  /// The URL for the OpenAI compatible API.
  final String? url;

  /// The model that should be used.
  final String model;

  /// The app description that will be part of the "system" prompt.
  /// Usually, this provides the model with some context for more
  /// accurate results.
  final String description;

  /// The maximum amount of characters that can be sent to the OpenAI API
  /// in one request. Lower values will result in more requests.
  final int? maxInputLength;

  /// The temperature parameter for the OpenAI API (if supported).
  final double? temperature;

  /// List of excluded target locales.
  final List<I18nLocale> excludes;

  const OpenaiConfig({
    required this.url,
    required this.model,
    required this.description,
    required this.maxInputLength,
    required this.temperature,
    required this.excludes,
  });

  static OpenaiConfig fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? openai = map['openai'];

    if (openai == null) {
      throw 'Missing openai entry in config.';
    }

    final url = openai['url'];

    final model = openai['model'];
    if (model == null) {
      throw 'Missing model entry in config.';
    }

    final description = openai['description'];
    if (description == null) {
      throw 'Missing description';
    }

    return OpenaiConfig(
      url: url,
      model: model,
      description: description,
      maxInputLength: openai['max_input_length'],
      temperature: openai['temperature']?.toDouble(),
      excludes: (openai['excludes'] as List?)
              ?.map((e) => I18nLocale.fromString(e))
              .toList() ??
          [],
    );
  }
}
