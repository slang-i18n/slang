import 'dart:io';

import 'package:fast_i18n/builder/model/context_type.dart';
import 'package:fast_i18n/builder/model/i18n_locale.dart';
import 'package:fast_i18n/builder/model/interface.dart';

/// represents a build.yaml
class BuildConfig {
  static const String defaultBaseLocale = 'en';
  static const FallbackStrategy defaultFallbackStrategy = FallbackStrategy.none;
  static const String? defaultInputDirectory = null;
  static const String defaultInputFilePattern = '.i18n.json';
  static const String? defaultOutputDirectory = null;
  static const String defaultOutputFilePattern = '.g.dart';
  static const String? defaultOutputFileName = null;
  static const OutputFormat defaultOutputFormat = OutputFormat.singleFile;
  static const bool defaultRenderLocaleHandling = true;
  static const bool defaultDartOnly = false;
  static const bool defaultNamespaces = false;
  static const String defaultTranslateVar = 't';
  static const String defaultEnumName = 'AppLocale';
  static const TranslationClassVisibility defaultTranslationClassVisibility =
      TranslationClassVisibility.private;
  static const CaseStyle? defaultKeyCase = null;
  static const CaseStyle? defaultKeyMapCase = null;
  static const CaseStyle? defaultParamCase = null;
  static const StringInterpolation defaultStringInterpolation =
      StringInterpolation.dart;
  static const bool defaultRenderFlatMap = true;
  static const bool defaultRenderTimestamp = true;
  static const List<String> defaultMaps = <String>[];
  static const PluralAuto defaultPluralAuto = PluralAuto.cardinal;
  static const List<String> defaultCardinal = <String>[];
  static const List<String> defaultOrdinal = <String>[];
  static const List<ContextType> defaultContexts = <ContextType>[];
  static const List<InterfaceConfig> defaultInterfaces = <InterfaceConfig>[];

  final FileType fileType;
  final I18nLocale baseLocale;
  final FallbackStrategy fallbackStrategy;
  final String? inputDirectory;
  final String inputFilePattern;
  final String? outputDirectory;
  final String outputFilePattern; // deprecated
  final String? outputFileName;
  final OutputFormat outputFormat;
  final bool renderLocaleHandling;
  final bool dartOnly;
  final bool namespaces;
  final String translateVar;
  final String enumName;
  final TranslationClassVisibility translationClassVisibility;
  final CaseStyle? keyCase;
  final CaseStyle? keyMapCase;
  final CaseStyle? paramCase;
  final StringInterpolation stringInterpolation;
  final bool renderFlatMap;
  final bool renderTimestamp;
  final List<String> maps;
  final PluralAuto pluralAuto;
  final List<String> pluralCardinal;
  final List<String> pluralOrdinal;
  final List<ContextType> contexts;
  final List<InterfaceConfig> interfaces;

  BuildConfig({
    required this.baseLocale,
    required this.fallbackStrategy,
    required this.inputDirectory,
    required this.inputFilePattern,
    required this.outputDirectory,
    required this.outputFilePattern,
    required this.outputFileName,
    required this.outputFormat,
    required this.renderLocaleHandling,
    required this.dartOnly,
    required this.namespaces,
    required this.translateVar,
    required this.enumName,
    required this.translationClassVisibility,
    required this.keyCase,
    required this.keyMapCase,
    required this.paramCase,
    required this.stringInterpolation,
    required this.renderFlatMap,
    required this.renderTimestamp,
    required this.maps,
    required this.pluralAuto,
    required this.pluralCardinal,
    required this.pluralOrdinal,
    required this.contexts,
    required this.interfaces,
  }) : fileType = _determineFileType(inputFilePattern);

  static FileType _determineFileType(String extension) {
    if (extension.endsWith('.json')) {
      return FileType.json;
    } else if (extension.endsWith('.yaml')) {
      return FileType.yaml;
    } else if (extension.endsWith('.csv')) {
      return FileType.csv;
    } else {
      throw 'Input file pattern must end with .json or .yaml (Input: $extension)';
    }
  }

  BuildConfig withAbsolutePaths() {
    return BuildConfig(
      baseLocale: baseLocale,
      fallbackStrategy: fallbackStrategy,
      inputDirectory: inputDirectory?.toAbsolutePath(),
      inputFilePattern: inputFilePattern,
      outputDirectory: outputDirectory?.toAbsolutePath(),
      outputFilePattern: outputFilePattern,
      outputFileName: outputFileName,
      outputFormat: outputFormat,
      renderLocaleHandling: renderLocaleHandling,
      dartOnly: dartOnly,
      namespaces: namespaces,
      translateVar: translateVar,
      enumName: enumName,
      translationClassVisibility: translationClassVisibility,
      keyCase: keyCase,
      keyMapCase: keyMapCase,
      paramCase: paramCase,
      stringInterpolation: stringInterpolation,
      renderFlatMap: renderFlatMap,
      renderTimestamp: renderTimestamp,
      maps: maps,
      pluralAuto: pluralAuto,
      pluralCardinal: pluralCardinal,
      pluralOrdinal: pluralOrdinal,
      contexts: contexts,
      interfaces: interfaces,
    );
  }

  void printConfig() {
    print(' -> fileType: ${fileType.getEnumName()}');
    print(' -> baseLocale: ${baseLocale.languageTag}');
    print(' -> fallbackStrategy: ${fallbackStrategy.getEnumName()}');
    print(
        ' -> inputDirectory: ${inputDirectory != null ? inputDirectory : 'null (everywhere)'}');
    print(' -> inputFilePattern: $inputFilePattern');
    print(
        ' -> outputDirectory: ${outputDirectory != null ? outputDirectory : 'null (directory of input)'}');
    print(' -> outputFilePattern (deprecated): $outputFilePattern');
    print(' -> outputFileName: $outputFileName');
    print(' -> outputFileFormat: ${outputFormat.getEnumName()}');
    print(' -> renderLocaleHandling: $renderLocaleHandling');
    print(' -> dartOnly: $dartOnly');
    print(' -> namespaces: $namespaces');
    print(' -> translateVar: $translateVar');
    print(' -> enumName: $enumName');
    print(
        ' -> translationClassVisibility: ${translationClassVisibility.getEnumName()}');
    print(
        ' -> keyCase: ${keyCase != null ? keyCase?.getEnumName() : 'null (no change)'}');
    print(
        ' -> keyCase (for maps): ${keyMapCase != null ? keyMapCase?.getEnumName() : 'null (no change)'}');
    print(
        ' -> paramCase: ${paramCase != null ? paramCase?.getEnumName() : 'null (no change)'}');
    print(' -> stringInterpolation: ${stringInterpolation.getEnumName()}');
    print(' -> renderFlatMap: $renderFlatMap');
    print(' -> renderTimestamp: $renderTimestamp');
    print(' -> maps: $maps');
    print(' -> pluralization/auto: ${pluralAuto.getEnumName()}');
    print(' -> pluralization/cardinal: $pluralCardinal');
    print(' -> pluralization/ordinal: $pluralOrdinal');
    print(' -> contexts: ${contexts.isEmpty ? 'no custom contexts' : ''}');
    for (final contextType in contexts) {
      print(
          '    - ${contextType.enumName} { ${contextType.enumValues.join(', ')} }');
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
  }
}

enum FileType { json, yaml, csv }

enum FallbackStrategy { none, baseLocale }

enum OutputFormat { singleFile, multipleFiles }

enum StringInterpolation { dart, braces, doubleBraces }

enum TranslationClassVisibility { private, public }

enum CaseStyle { camel, pascal, snake }

enum PluralAuto { off, cardinal, ordinal }

extension Parser on String {
  FallbackStrategy? toFallbackStrategy() {
    switch (this) {
      case 'none':
        return FallbackStrategy.none;
      case 'base_locale':
        return FallbackStrategy.baseLocale;
      default:
        return null;
    }
  }

  OutputFormat? toOutputFormat() {
    switch (this) {
      case 'single_file':
        return OutputFormat.singleFile;
      case 'multiple_files':
        return OutputFormat.multipleFiles;
      default:
        return null;
    }
  }

  TranslationClassVisibility? toTranslationClassVisibility() {
    switch (this) {
      case 'private':
        return TranslationClassVisibility.private;
      case 'public':
        return TranslationClassVisibility.public;
      default:
        return null;
    }
  }

  StringInterpolation? toStringInterpolation() {
    switch (this) {
      case 'dart':
        return StringInterpolation.dart;
      case 'braces':
        return StringInterpolation.braces;
      case 'double_braces':
        return StringInterpolation.doubleBraces;
      default:
        return null;
    }
  }

  CaseStyle? toCaseStyle() {
    switch (this) {
      case 'camel':
        return CaseStyle.camel;
      case 'snake':
        return CaseStyle.snake;
      case 'pascal':
        return CaseStyle.pascal;
      default:
        return null;
    }
  }

  PluralAuto? toPluralAuto() {
    switch (this) {
      case 'off':
        return PluralAuto.off;
      case 'cardinal':
        return PluralAuto.cardinal;
      case 'ordinal':
        return PluralAuto.ordinal;
      default:
        return null;
    }
  }

  /// converts to absolute file path
  String toAbsolutePath() {
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

extension on Object {
  /// expects an enum and get its string representation without enum class name
  String getEnumName() {
    return this.toString().split('.').last;
  }
}
