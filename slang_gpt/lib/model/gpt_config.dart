import 'package:collection/collection.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang_gpt/model/gpt_model.dart';

/// Represents the gpt node in build.yaml
class GptConfig {
  /// The GPT model that should be used.
  final GptModel model;

  /// The app description that will be part of the "system" prompt.
  /// Usually, this provides the GPT model with some context for more
  /// accurate results.
  final String description;

  /// The maximum amount of characters that can be sent to the GPT API
  /// in one request. Lower values will result in more requests.
  final int maxInputLength;

  /// The temperature parameter for the GPT API (if supported).
  final double? temperature;

  /// List of excluded target locales.
  final List<I18nLocale> excludes;

  const GptConfig({
    required this.model,
    required this.description,
    required this.maxInputLength,
    required this.temperature,
    required this.excludes,
  });

  static GptConfig fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? gpt = map['gpt'];

    if (gpt == null) {
      throw 'Missing gpt entry in config.';
    }

    final model = GptModel.values.firstWhereOrNull((e) => e.id == gpt['model']);
    if (model == null) {
      throw 'Unknown model: ${gpt['model']}\nAvailable models: ${GptModel.values.map((e) => e.id).join(', ')}';
    }

    final description = gpt['description'];
    if (description == null) {
      throw 'Missing description';
    }

    return GptConfig(
      model: model,
      description: description,
      maxInputLength: gpt['max_input_length'] ?? model.defaultInputLength,
      temperature: gpt['temperature']?.toDouble(),
      excludes: (gpt['excludes'] as List?)
              ?.map((e) => I18nLocale.fromString(e))
              .toList() ??
          [],
    );
  }
}
