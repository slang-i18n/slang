import 'package:collection/collection.dart';
import 'package:slang_gpt/model/gpt_model.dart';

/// Represents the gpt node in build.yaml
class GptConfig {
  final GptModel model;
  final String description;
  final int maxInputLength;
  final double? temperature;

  const GptConfig({
    required this.model,
    required this.description,
    required this.maxInputLength,
    required this.temperature,
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
    );
  }
}
