import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/context_type.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/string_extensions.dart';

class BuildConfigBuilder {
  static BuildConfig fromMap(Map<String, dynamic> map) {
    final contextMap =
        map['contexts']?.cast<String, dynamic>() as Map<String, dynamic>?;
    List<ContextType> contextTypes = [];
    if (contextMap != null) {
      contextTypes = contextMap.entries.map((e) {
        final enumName = e.key.toCase(KeyCase.pascal);
        final config = e.value.cast<String, dynamic>() as Map<String, dynamic>;

        return ContextType(
          enumName: enumName,
          enumValues: (config['enum'].cast<String>() as List<String>)
              .map((e) => e.toCase(KeyCase.camel))
              .toList(),
          auto: config['auto'] ?? ContextType.defaultAuto,
          paths: config['paths']?.cast<String>() ?? ContextType.defaultPaths,
        );
      }).toList();
    }

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
      translateVar: map['translate_var'] ?? BuildConfig.defaultTranslateVar,
      enumName: map['enum_name'] ?? BuildConfig.defaultEnumName,
      translationClassVisibility:
          (map['translation_class_visibility'] as String?)
                  ?.toTranslationClassVisibility() ??
              BuildConfig.defaultTranslationClassVisibility,
      keyCase: (map['key_case'] as String?)?.toKeyCase() ??
          BuildConfig.defaultKeyCase,
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
      contexts: contextTypes,
    );
  }
}
