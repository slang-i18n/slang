import 'package:slang/builder/model/build_config.dart';
import 'package:slang/builder/model/context_type.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/interface.dart';

final defaultLocale = I18nLocale.fromString(BuildConfig.defaultBaseLocale);

final baseConfig = BuildConfig(
  baseLocale: defaultLocale,
  fallbackStrategy: BuildConfig.defaultFallbackStrategy,
  inputDirectory: BuildConfig.defaultInputDirectory,
  inputFilePattern: BuildConfig.defaultInputFilePattern,
  outputDirectory: BuildConfig.defaultOutputDirectory,
  outputFileName: BuildConfig.defaultOutputFileName,
  outputFormat: BuildConfig.defaultOutputFormat,
  localeHandling: BuildConfig.defaultLocaleHandling,
  flutterIntegration: BuildConfig.defaultFlutterIntegration,
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
    bool? flutterIntegration,
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
      outputFileName: outputFileName,
      outputFormat: outputFormat ?? this.outputFormat,
      localeHandling: renderLocaleHandling ?? this.localeHandling,
      flutterIntegration: flutterIntegration ?? this.flutterIntegration,
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
