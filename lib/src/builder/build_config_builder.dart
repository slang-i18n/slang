import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/context_type.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/string_extensions.dart';
import 'package:fast_i18n/src/utils/yaml_utils.dart';
import 'package:yaml/yaml.dart';

class BuildConfigBuilder {

  /// Parses the full build.yaml file to get the config
  /// May return null if no config entry is found.
  static BuildConfig? fromYaml(String rawYaml) {
    final parsedYaml = loadYaml(rawYaml);
    final configEntry = _findConfigEntry(parsedYaml);
    if (configEntry == null) {
      return null;
    }

    final map = YamlUtils.deepCast(configEntry.value);
    return fromMap(map);
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

  /// Parses the config entry
  static BuildConfig fromMap(Map<String, dynamic> map) {
    return BuildConfig(
      baseLocale: I18nLocale.fromString(
          map['base_locale'] ?? BuildConfig.defaultBaseLocale),
      fallbackStrategy:
          (map['fallback_strategy'] as String?)?.toFallbackStrategy() ??
              BuildConfig.defaultFallbackStrategy,
      inputDirectory:
          map['input_directory'] ?? BuildConfig.defaultInputDirectory,
      inputFilePattern:
          map['input_file_pattern'] ?? BuildConfig.defaultInputFilePattern,
      outputDirectory:
          map['output_directory'] ?? BuildConfig.defaultOutputDirectory,
      outputFilePattern:
          map['output_file_pattern'] ?? BuildConfig.defaultOutputFilePattern,
      outputFileName: map['output_file_name'] ?? BuildConfig.defaultOutputFileName,
      namespaces: map['namespaces'] ?? BuildConfig.defaultNamespaces,
      translateVar: map['translate_var'] ?? BuildConfig.defaultTranslateVar,
      enumName: map['enum_name'] ?? BuildConfig.defaultEnumName,
      translationClassVisibility:
          (map['translation_class_visibility'] as String?)
                  ?.toTranslationClassVisibility() ??
              BuildConfig.defaultTranslationClassVisibility,
      keyCase: (map['key_case'] as String?)?.toCaseStyle() ??
          BuildConfig.defaultKeyCase,
      keyMapCase: (map['key_map_case'] as String?)?.toCaseStyle() ??
          BuildConfig.defaultKeyMapCase,
      paramCase: (map['param_case'] as String?)?.toCaseStyle() ??
          BuildConfig.defaultParamCase,
      stringInterpolation:
          (map['string_interpolation'] as String?)?.toStringInterpolation() ??
              BuildConfig.defaultStringInterpolation,
      renderFlatMap: map['flat_map'] ?? BuildConfig.defaultRenderFlatMap,
      maps: map['maps']?.cast<String>() ?? BuildConfig.defaultMaps,
      pluralAuto: (map['pluralization']?['auto'] as String?)?.toPluralAuto() ??
          BuildConfig.defaultPluralAuto,
      pluralCardinal: map['pluralization']?['cardinal']?.cast<String>() ??
          BuildConfig.defaultCardinal,
      pluralOrdinal: map['pluralization']?['ordinal']?.cast<String>() ??
          BuildConfig.defaultOrdinal,
      contexts: (map['contexts'] as Map<String, dynamic>?)?.toContextTypes() ??
          BuildConfig.defaultContexts,
    );
  }
}

extension on Map<String, dynamic> {
  /// Parses the 'contexts' config
  List<ContextType> toContextTypes() {
    return this.entries.map((e) {
      final enumName = e.key.toCase(CaseStyle.pascal);
      final config = e.value as Map<String, dynamic>;

      return ContextType(
        enumName: enumName,
        enumValues: (config['enum'].cast<String>() as List<String>)
            .map((e) => e.toCase(CaseStyle.camel))
            .toList(),
        auto: config['auto'] ?? ContextType.defaultAuto,
        paths: config['paths']?.cast<String>() ?? ContextType.defaultPaths,
      );
    }).toList();
  }
}
