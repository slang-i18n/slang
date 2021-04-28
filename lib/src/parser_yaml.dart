import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import "package:yaml/yaml.dart";

/// parses the yaml string according to build.yaml
BuildConfig parseBuildYaml(String? content) {
  YamlMap? config;
  if (content != null) {
    final map = loadYaml(content);
    config = _findConfigEntry(map);
  }

  final baseLocale = I18nLocale.fromString(
      config?['base_locale'] ?? BuildConfig.defaultBaseLocale);
  final inputDirectory =
      config?['input_directory'] ?? BuildConfig.defaultInputDirectory;
  final inputFilePattern =
      config?['input_file_pattern'] ?? BuildConfig.defaultInputFilePattern;
  final outputDirectory =
      config?['output_directory'] ?? BuildConfig.defaultOutputDirectory;
  final outputFilePattern =
      config?['output_file_pattern'] ?? BuildConfig.defaultOutputFilePattern;
  final translateVar =
      config?['translate_var'] ?? BuildConfig.defaultTranslateVar;
  final enumName = config?['enum_name'] ?? BuildConfig.defaultEnumName;
  final translationClassVisibility =
      (config?['translation_class_visibility'] as String?)
              ?.toTranslationClassVisibility() ??
          BuildConfig.defaultTranslationClassVisibility;
  final keyCase = (config?['key_case'] as String?)?.toKeyCase() ??
      BuildConfig.defaultKeyCase;
  final maps = config?['maps']?.cast<String>() ?? BuildConfig.defaultMaps;

  return BuildConfig(
      baseLocale: baseLocale,
      inputDirectory: inputDirectory,
      inputFilePattern: inputFilePattern,
      outputDirectory: outputDirectory,
      outputFilePattern: outputFilePattern,
      translateVar: translateVar,
      enumName: enumName,
      translationClassVisibility: translationClassVisibility,
      keyCase: keyCase,
      maps: maps);
}

YamlMap? _findConfigEntry(YamlMap parent) {
  for (final entry in parent.entries) {
    if (entry.key == 'fast_i18n:i18nBuilder' && entry.value is YamlMap) {
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
