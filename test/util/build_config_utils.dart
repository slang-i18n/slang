import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';

final defaultLocale = I18nLocale.fromString(BuildConfig.defaultBaseLocale);

final baseConfig = BuildConfig(
  baseLocale: defaultLocale,
  fallbackStrategy: BuildConfig.defaultFallbackStrategy,
  inputDirectory: BuildConfig.defaultInputDirectory,
  inputFilePattern: BuildConfig.defaultInputFilePattern,
  outputDirectory: BuildConfig.defaultOutputDirectory,
  outputFilePattern: BuildConfig.defaultOutputFilePattern,
  translateVar: BuildConfig.defaultTranslateVar,
  enumName: BuildConfig.defaultEnumName,
  translationClassVisibility: BuildConfig.defaultTranslationClassVisibility,
  keyCase: BuildConfig.defaultKeyCase,
  keyMapCase: BuildConfig.defaultKeyMapCase,
  paramCase: BuildConfig.defaultParamCase,
  stringInterpolation: BuildConfig.defaultStringInterpolation,
  renderFlatMap: BuildConfig.defaultRenderFlatMap,
  maps: BuildConfig.defaultMaps,
  pluralAuto: BuildConfig.defaultPluralAuto,
  pluralCardinal: BuildConfig.defaultCardinal,
  pluralOrdinal: BuildConfig.defaultOrdinal,
  contexts: BuildConfig.defaultContexts,
);

extension BuildConfigCopy on BuildConfig {
  BuildConfig copyWith({
    CaseStyle? keyCase,
    CaseStyle? keyMapCase,
    List<String>? maps,
    PluralAuto? pluralAuto,
    List<String>? pluralCardinal,
    List<String>? pluralOrdinal,
  }) {
    return BuildConfig(
      baseLocale: baseLocale,
      fallbackStrategy: fallbackStrategy,
      inputDirectory: inputDirectory,
      inputFilePattern: inputFilePattern,
      outputDirectory: outputDirectory,
      outputFilePattern: outputFilePattern,
      translateVar: translateVar,
      enumName: enumName,
      translationClassVisibility: translationClassVisibility,
      keyCase: keyCase ?? this.keyCase,
      keyMapCase: keyMapCase ?? this.keyMapCase,
      paramCase: paramCase,
      stringInterpolation: stringInterpolation,
      renderFlatMap: renderFlatMap,
      maps: maps ?? this.maps,
      pluralAuto: pluralAuto ?? this.pluralAuto,
      pluralCardinal: pluralCardinal ?? this.pluralCardinal,
      pluralOrdinal: pluralOrdinal ?? this.pluralOrdinal,
      contexts: BuildConfig.defaultContexts,
    );
  }
}
