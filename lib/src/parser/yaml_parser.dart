import 'package:fast_i18n/src/builder/build_config_builder.dart';
import 'package:fast_i18n/src/builder/node_builder.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:yaml/yaml.dart';

class YamlParser {
  /// parses a yaml according to build.yaml
  static BuildConfig? parseBuildYaml(String rawYaml) {
    final parsedYaml = loadYaml(rawYaml);
    final configEntry = _findConfigEntry(parsedYaml);
    if (configEntry == null) {
      return null;
    }

    final map = deepCast(configEntry.value);
    return BuildConfigBuilder.fromMap(map);
  }

  /// parses a yaml of one locale
  /// returns an I18nData object
  static I18nData parseTranslations(
      BuildConfig config, I18nLocale locale, String content) {
    final map = loadYaml(content);
    final buildResult = NodeBuilder.fromMap(config, locale, deepCast(map));
    return I18nData(
      base: config.baseLocale == locale,
      locale: locale,
      root: buildResult.root,
      hasCardinal: buildResult.hasCardinal,
      hasOrdinal: buildResult.hasOrdinal,
    );
  }

  /// Returns the part of the yaml file which is "important"
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

  /// converts Map<dynamic, dynamic> to Map<String, dynamic> for all children
  /// forcing all keys to be strings
  static Map<String, dynamic> deepCast(Map<dynamic, dynamic> source) {
    return source.map((key, value) {
      final castedValue;
      if (value is Map) {
        castedValue = deepCast(value);
      } else if (value is List) {
        castedValue = _deepCastList(value);
      } else {
        castedValue = value;
      }
      return MapEntry(key.toString(), castedValue);
    });
  }

  /// Helper function for [deepCast] handling lists
  static List<dynamic> _deepCastList(List<dynamic> source) {
    return source.map((item) {
      if (item is Map) {
        return deepCast(item);
      } else if (item is List) {
        return _deepCastList(item);
      } else {
        return item;
      }
    }).toList();
  }
}
