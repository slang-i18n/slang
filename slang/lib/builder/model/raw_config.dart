import 'dart:io';

import 'package:slang/builder/model/context_type.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/interface.dart';

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
  final List<String> imports;

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
    required this.imports,
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

  RawConfig withAbsolutePaths() {
    return RawConfig(
      baseLocale: baseLocale,
      fallbackStrategy: fallbackStrategy,
      inputDirectory: inputDirectory?.toAbsolutePath(),
      inputFilePattern: inputFilePattern,
      outputDirectory: outputDirectory?.toAbsolutePath(),
      outputFileName: outputFileName,
      outputFormat: outputFormat,
      localeHandling: localeHandling,
      flutterIntegration: flutterIntegration,
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
      imports: imports,
    );
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
    print(' -> renderTimestamp: $renderTimestamp');
    print(' -> maps: $maps');
    print(' -> pluralization/auto: ${pluralAuto.name}');
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
    print(' -> imports: $imports');
  }
}

extension RawConfigStringExt on String {
  /// converts to absolute file path
  String toAbsolutePath() {
    String result = this
        .replaceAll('/', Platform.pathSeparator)
        .replaceAll('\\', Platform.pathSeparator);

    if (result.startsWith(Platform.pathSeparator)) {
      result = result.substring(Platform.pathSeparator.length);
    }

    if (result.endsWith(Platform.pathSeparator)) {
      result =
          result.substring(0, result.length - Platform.pathSeparator.length);
    }

    return Directory.current.path + Platform.pathSeparator + result;
  }
}
