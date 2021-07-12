import 'package:fast_i18n/src/builder/build_config_builder.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:yaml/yaml.dart';

class YamlParser {
  /// parses the yaml string according to build.yaml
  static BuildConfig? parseBuildYaml(String yamlContent) {
    final map = loadYaml(yamlContent);
    final configEntry = _findConfigEntry(map);
    if (configEntry == null) {
      return null;
    }

    return BuildConfigBuilder.fromMap(
        configEntry.value.cast<String, dynamic>());
  }

  static YamlMap? _findConfigEntry(YamlMap parent) {
    for (final entry in parent.entries) {
      if (entry.key == 'fast_i18n' && entry.value is YamlMap) {
        final options = entry.value['options'];
        if (options != null) return options; // found
      }

      if (entry.value is YamlMap) {
        final result = _findConfigEntry(entry.value);
        if (result != null) {
          return result; // found
        }
      }
    }
  }
}
