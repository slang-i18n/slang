import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/context_type.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/interface.dart';

final defaultLocale = I18nLocale.fromString(BuildConfig.defaultBaseLocale);

final baseConfig = BuildConfig(
  baseLocale: defaultLocale,
  fallbackStrategy: BuildConfig.defaultFallbackStrategy,
  inputDirectory: BuildConfig.defaultInputDirectory,
  inputFilePattern: BuildConfig.defaultInputFilePattern,
  outputDirectory: BuildConfig.defaultOutputDirectory,
  outputFilePattern: BuildConfig.defaultOutputFilePattern,
  outputFileName: BuildConfig.defaultOutputFileName,
  outputFormat: BuildConfig.defaultOutputFormat,
  renderLocaleHandling: BuildConfig.defaultRenderLocaleHandling,
  namespaces: BuildConfig.defaultNamespaces,
  translateVar: BuildConfig.defaultTranslateVar,
  enumName: BuildConfig.defaultEnumName,
  translationClassVisibility: BuildConfig.defaultTranslationClassVisibility,
  keyCase: BuildConfig.defaultKeyCase,
  keyMapCase: BuildConfig.defaultKeyMapCase,
  paramCase: BuildConfig.defaultParamCase,
  stringInterpolation: BuildConfig.defaultStringInterpolation,
  renderFlatMap: BuildConfig.defaultRenderFlatMap,
  renderTimestamp: BuildConfig.defaultRenderTimestamp,
  maps: BuildConfig.defaultMaps,
  pluralAuto: BuildConfig.defaultPluralAuto,
  pluralCardinal: BuildConfig.defaultCardinal,
  pluralOrdinal: BuildConfig.defaultOrdinal,
  contexts: BuildConfig.defaultContexts,
  interfaces: BuildConfig.defaultInterfaces,
);

extension BuildConfigCopy on BuildConfig {
  BuildConfig copyWith({
    String? inputFilePattern,
    OutputFormat? outputFormat,
    bool? renderLocaleHandling,
    CaseStyle? keyCase,
    CaseStyle? keyMapCase,
    List<String>? maps,
    PluralAuto? pluralAuto,
    List<String>? pluralCardinal,
    List<String>? pluralOrdinal,
    List<ContextType>? contexts,
    List<InterfaceConfig>? interfaces,
  }) {
    return BuildConfig(
      baseLocale: baseLocale,
      fallbackStrategy: fallbackStrategy,
      inputDirectory: inputDirectory,
      inputFilePattern: inputFilePattern ?? this.inputFilePattern,
      outputDirectory: outputDirectory,
      outputFilePattern: outputFilePattern,
      outputFileName: outputFileName,
      outputFormat: outputFormat ?? this.outputFormat,
      renderLocaleHandling: renderLocaleHandling ?? this.renderLocaleHandling,
      namespaces: namespaces,
      translateVar: translateVar,
      enumName: enumName,
      translationClassVisibility: translationClassVisibility,
      keyCase: keyCase ?? this.keyCase,
      keyMapCase: keyMapCase ?? this.keyMapCase,
      paramCase: paramCase,
      stringInterpolation: stringInterpolation,
      renderFlatMap: renderFlatMap,
      renderTimestamp: renderTimestamp,
      maps: maps ?? this.maps,
      pluralAuto: pluralAuto ?? this.pluralAuto,
      pluralCardinal: pluralCardinal ?? this.pluralCardinal,
      pluralOrdinal: pluralOrdinal ?? this.pluralOrdinal,
      contexts: contexts ?? this.contexts,
      interfaces: interfaces ?? this.interfaces,
    );
  }
}
