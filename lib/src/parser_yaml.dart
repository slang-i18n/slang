import 'dart:io';

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
  final inputDirectory = ((config?['input_directory'] as String?) ??
          BuildConfig.defaultInputDirectory)
      ?.normalizePath();
  final inputFilePattern =
      config?['input_file_pattern'] ?? BuildConfig.defaultInputFilePattern;
  final outputDirectory = ((config?['output_directory'] as String?) ??
          BuildConfig.defaultOutputDirectory)
      ?.normalizePath();
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
  final pluralCardinal =
      config?['pluralization']?['cardinal']?.cast<String>() ??
          BuildConfig.defaultCardinal;
  final pluralOrdinal = config?['pluralization']?['ordinal']?.cast<String>() ??
      BuildConfig.defaultOrdinal;

  final bool nullSafety;
  if (config?['null_safety'] != null) {
    nullSafety = config?['null_safety'] == 'true';
  } else {
    nullSafety = BuildConfig.defaultNullSafety;
  }

  return BuildConfig(
      nullSafety: nullSafety,
      baseLocale: baseLocale,
      inputDirectory: inputDirectory,
      inputFilePattern: inputFilePattern,
      outputDirectory: outputDirectory,
      outputFilePattern: outputFilePattern,
      translateVar: translateVar,
      enumName: enumName,
      translationClassVisibility: translationClassVisibility,
      keyCase: keyCase,
      maps: maps,
      pluralCardinal: pluralCardinal,
      pluralOrdinal: pluralOrdinal);
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

extension on String {
  String normalizePath() {
    String result = this
        .replaceAll('/', Platform.pathSeparator)
        .replaceAll('\\', Platform.pathSeparator);

    if (result.startsWith(Platform.pathSeparator))
      result = result.substring(Platform.pathSeparator.length);

    if (result.endsWith(Platform.pathSeparator))
      result =
          result.substring(0, result.length - Platform.pathSeparator.length);

    return Directory.current.path + Platform.pathSeparator + result;
  }
}
