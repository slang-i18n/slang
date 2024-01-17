import 'package:slang/builder/model/context_type.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/interface.dart';
import 'package:slang/builder/model/obfuscation_config.dart';

/// represents a build.yaml
class RawConfig {
  static const String defaultBaseLocale = 'en';
  static const FallbackStrategy defaultFallbackStrategy = FallbackStrategy.none;
  static const String? defaultInputDirectory = null;
  static const String defaultInputFilePattern = '.i18n.json';
  static const String? defaultOutputDirectory = null;
  static const String defaultOutputFileName = 'strings.g.dart';
  static const OutputFormat defaultOutputFormat = OutputFormat.singleFile;
  static const bool defaultLocaleHandling = true;
  static const bool defaultFlutterIntegration = true;
  static const bool defaultNamespaces = false;
  static const String defaultTranslateVar = 't';
  static const String defaultEnumName = 'AppLocale';
  static const String defaultClassName = 'Translations';
  static const TranslationClassVisibility defaultTranslationClassVisibility =
      TranslationClassVisibility.private;
  static const CaseStyle? defaultKeyCase = null;
  static const CaseStyle? defaultKeyMapCase = null;
  static const CaseStyle? defaultParamCase = null;
  static const StringInterpolation defaultStringInterpolation =
      StringInterpolation.dart;
  static const bool defaultRenderFlatMap = true;
  static const bool defaultTranslationOverrides = false;
  static const bool defaultRenderTimestamp = true;
  static const bool defaultRenderStatistics = true;
  static const List<String> defaultMaps = <String>[];
  static const PluralAuto defaultPluralAuto = PluralAuto.cardinal;
  static const String defaultPluralParameter = 'n';
  static const List<String> defaultCardinal = <String>[];
  static const List<String> defaultOrdinal = <String>[];
  static const List<ContextType> defaultContexts = <ContextType>[];
  static const List<InterfaceConfig> defaultInterfaces = <InterfaceConfig>[];
  static final ObfuscationConfig defaultObfuscationConfig =
      ObfuscationConfig.disabled();
  static const List<String> defaultImports = <String>[];

  final FileType fileType;
  final I18nLocale baseLocale;
  final FallbackStrategy fallbackStrategy;
  final String? inputDirectory;
  final String inputFilePattern;
  final String? outputDirectory;
  final String outputFileName;
  final OutputFormat outputFormat;
  final bool localeHandling;
  final bool flutterIntegration;
  final bool namespaces;
  final String translateVar;
  final String enumName;
  final String className;
  final TranslationClassVisibility translationClassVisibility;
  final CaseStyle? keyCase;
  final CaseStyle? keyMapCase;
  final CaseStyle? paramCase;
  final StringInterpolation stringInterpolation;
  final bool renderFlatMap;
  final bool translationOverrides;
  final bool renderTimestamp;
  final bool renderStatistics;
  final List<String> maps;
  final PluralAuto pluralAuto;
  final String pluralParameter;
  final List<String> pluralCardinal;
  final List<String> pluralOrdinal;
  final List<ContextType> contexts;
  final List<InterfaceConfig> interfaces;
  final ObfuscationConfig obfuscation;
  final List<String> imports;

  /// Used by external tools to access the raw config. (e.g. slang_gpt)
  final Map<String, dynamic> rawMap;

  RawConfig({
    required this.baseLocale,
    required this.fallbackStrategy,
    required this.inputDirectory,
    required this.inputFilePattern,
    required this.outputDirectory,
    required this.outputFileName,
    required this.outputFormat,
    required this.localeHandling,
    required this.flutterIntegration,
    required this.namespaces,
    required this.translateVar,
    required this.enumName,
    required this.className,
    required this.translationClassVisibility,
    required this.keyCase,
    required this.keyMapCase,
    required this.paramCase,
    required StringInterpolation stringInterpolation,
    required this.renderFlatMap,
    required this.translationOverrides,
    required this.renderTimestamp,
    required this.renderStatistics,
    required this.maps,
    required this.pluralAuto,
    required this.pluralParameter,
    required this.pluralCardinal,
    required this.pluralOrdinal,
    required this.contexts,
    required this.interfaces,
    required this.obfuscation,
    required this.imports,
    required this.rawMap,
  })  : fileType = _determineFileType(inputFilePattern),
        stringInterpolation =
            _determineFileType(inputFilePattern) == FileType.arb
                ? StringInterpolation.braces
                : stringInterpolation;

  RawConfig copyWith({
    I18nLocale? baseLocale,
    FallbackStrategy? fallbackStrategy,
    String? inputFilePattern,
    String? outputFileName,
    OutputFormat? outputFormat,
    bool? localeHandling,
    bool? flutterIntegration,
    bool? namespaces,
    TranslationClassVisibility? translationClassVisibility,
    CaseStyle? keyCase,
    CaseStyle? keyMapCase,
    bool? renderFlatMap,
    bool? translationOverrides,
    bool? renderTimestamp,
    bool? renderStatistics,
    List<String>? maps,
    PluralAuto? pluralAuto,
    List<String>? pluralCardinal,
    List<String>? pluralOrdinal,
    List<ContextType>? contexts,
    List<InterfaceConfig>? interfaces,
    ObfuscationConfig? obfuscation,
  }) {
    return RawConfig(
      baseLocale: baseLocale ?? this.baseLocale,
      fallbackStrategy: fallbackStrategy ?? this.fallbackStrategy,
      inputDirectory: inputDirectory,
      inputFilePattern: inputFilePattern ?? this.inputFilePattern,
      outputDirectory: outputDirectory,
      outputFileName: outputFileName ?? this.outputFileName,
      outputFormat: outputFormat ?? this.outputFormat,
      localeHandling: localeHandling ?? this.localeHandling,
      flutterIntegration: flutterIntegration ?? this.flutterIntegration,
      namespaces: namespaces ?? this.namespaces,
      translateVar: translateVar,
      enumName: enumName,
      className: className,
      translationClassVisibility:
          translationClassVisibility ?? this.translationClassVisibility,
      keyCase: keyCase ?? this.keyCase,
      keyMapCase: keyMapCase ?? this.keyMapCase,
      paramCase: paramCase,
      stringInterpolation: stringInterpolation,
      renderFlatMap: renderFlatMap ?? this.renderFlatMap,
      translationOverrides: translationOverrides ?? this.translationOverrides,
      renderTimestamp: renderTimestamp ?? this.renderTimestamp,
      renderStatistics: renderStatistics ?? this.renderStatistics,
      maps: maps ?? this.maps,
      pluralAuto: pluralAuto ?? this.pluralAuto,
      pluralParameter: pluralParameter,
      pluralCardinal: pluralCardinal ?? this.pluralCardinal,
      pluralOrdinal: pluralOrdinal ?? this.pluralOrdinal,
      contexts: contexts ?? this.contexts,
      interfaces: interfaces ?? this.interfaces,
      obfuscation: obfuscation ?? this.obfuscation,
      imports: imports,
      rawMap: rawMap,
    );
  }

  void validate() {
    if (translationOverrides && !renderFlatMap) {
      throw 'flat_map is deactivated but it is required by translation_overrides.';
    }
  }

  static FileType _determineFileType(String extension) {
    if (extension.endsWith('.json')) {
      return FileType.json;
    } else if (extension.endsWith('.yaml')) {
      return FileType.yaml;
    } else if (extension.endsWith('.csv')) {
      return FileType.csv;
    } else if (extension.endsWith('.arb')) {
      return FileType.arb;
    } else {
      throw 'Input file pattern must end with .json, .yaml, .csv, or .arb (Input: $extension)';
    }
  }

  void printConfig() {
    print(' -> fileType: ${fileType.name}');
    print(' -> baseLocale: ${baseLocale.languageTag}');
    print(' -> fallbackStrategy: ${fallbackStrategy.name}');
    print(
        ' -> inputDirectory: ${inputDirectory != null ? inputDirectory : 'null (everywhere)'}');
    print(' -> inputFilePattern: $inputFilePattern');
    print(
        ' -> outputDirectory: ${outputDirectory != null ? outputDirectory : 'null (directory of input)'}');
    print(' -> outputFileName: $outputFileName');
    print(' -> outputFileFormat: ${outputFormat.name}');
    print(' -> localeHandling: $localeHandling');
    print(' -> flutterIntegration: $flutterIntegration');
    print(' -> namespaces: $namespaces');
    print(' -> translateVar: $translateVar');
    print(' -> enumName: $enumName');
    print(' -> translationClassVisibility: ${translationClassVisibility.name}');
    print(
        ' -> keyCase: ${keyCase != null ? keyCase?.name : 'null (no change)'}');
    print(
        ' -> keyCase (for maps): ${keyMapCase != null ? keyMapCase?.name : 'null (no change)'}');
    print(
        ' -> paramCase: ${paramCase != null ? paramCase?.name : 'null (no change)'}');
    print(' -> stringInterpolation: ${stringInterpolation.name}');
    print(' -> renderFlatMap: $renderFlatMap');
    print(' -> translationOverrides: $translationOverrides');
    print(' -> renderTimestamp: $renderTimestamp');
    print(' -> renderStatistics: $renderStatistics');
    print(' -> maps: $maps');
    print(' -> pluralization/auto: ${pluralAuto.name}');
    print(' -> pluralization/default_parameter: $pluralParameter');
    print(' -> pluralization/cardinal: $pluralCardinal');
    print(' -> pluralization/ordinal: $pluralOrdinal');
    print(' -> contexts: ${contexts.isEmpty ? 'no custom contexts' : ''}');
    for (final contextType in contexts) {
      print(
          '    - ${contextType.enumName} { ${contextType.enumValues?.join(', ') ?? '(inferred)'} }');
    }
    print(' -> interfaces: ${interfaces.isEmpty ? 'no interfaces' : ''}');
    for (final interface in interfaces) {
      print('    - ${interface.name}');
      print(
          '        Attributes: ${interface.attributes.isEmpty ? 'no attributes' : ''}');
      for (final a in interface.attributes) {
        print(
            '          - ${a.returnType} ${a.attributeName} (${a.parameters.isEmpty ? 'no parameters' : a.parameters.map((p) => p.parameterName).join(',')})${a.optional ? ' (optional)' : ''}');
      }
      print('        Paths: ${interface.paths.isEmpty ? 'no paths' : ''}');
      for (final path in interface.paths) {
        print(
            '          - ${path.isContainer ? 'children of: ' : ''}${path.path}');
      }
    }
    print(' -> obfuscation: ${obfuscation.enabled ? 'enabled' : 'disabled'}');
    print(' -> imports: $imports');
  }

  static final defaultLocale =
      I18nLocale.fromString(RawConfig.defaultBaseLocale);

  static final defaultConfig = RawConfig(
    baseLocale: defaultLocale,
    fallbackStrategy: RawConfig.defaultFallbackStrategy,
    inputDirectory: RawConfig.defaultInputDirectory,
    inputFilePattern: RawConfig.defaultInputFilePattern,
    outputDirectory: RawConfig.defaultOutputDirectory,
    outputFileName: RawConfig.defaultOutputFileName,
    outputFormat: RawConfig.defaultOutputFormat,
    localeHandling: RawConfig.defaultLocaleHandling,
    flutterIntegration: RawConfig.defaultFlutterIntegration,
    namespaces: RawConfig.defaultNamespaces,
    translateVar: RawConfig.defaultTranslateVar,
    enumName: RawConfig.defaultEnumName,
    translationClassVisibility: RawConfig.defaultTranslationClassVisibility,
    keyCase: RawConfig.defaultKeyCase,
    keyMapCase: RawConfig.defaultKeyMapCase,
    paramCase: RawConfig.defaultParamCase,
    stringInterpolation: RawConfig.defaultStringInterpolation,
    renderFlatMap: RawConfig.defaultRenderFlatMap,
    translationOverrides: RawConfig.defaultTranslationOverrides,
    renderTimestamp: RawConfig.defaultRenderTimestamp,
    renderStatistics: RawConfig.defaultRenderStatistics,
    maps: RawConfig.defaultMaps,
    pluralAuto: RawConfig.defaultPluralAuto,
    pluralParameter: RawConfig.defaultPluralParameter,
    pluralCardinal: RawConfig.defaultCardinal,
    pluralOrdinal: RawConfig.defaultOrdinal,
    contexts: RawConfig.defaultContexts,
    interfaces: RawConfig.defaultInterfaces,
    obfuscation: RawConfig.defaultObfuscationConfig,
    imports: RawConfig.defaultImports,
    className: RawConfig.defaultClassName,
    rawMap: {},
  );
}
