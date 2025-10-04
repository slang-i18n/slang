import 'package:slang/src/builder/model/autodoc_config.dart';
import 'package:slang/src/builder/model/context_type.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/format_config.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/interface.dart';
import 'package:slang/src/builder/model/obfuscation_config.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/sanitization_config.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';
import 'package:slang/src/utils/log.dart' as log;
import 'package:yaml/yaml.dart';

class RawConfigBuilder {
  /// Parses the full build.yaml file to get the config
  /// May return null if no config entry is found.
  static RawConfig? fromYaml(String rawYaml, [bool isSlangYaml = false]) {
    final parsedYaml = loadYaml(rawYaml);
    if (parsedYaml == null) {
      return null;
    }
    final YamlMap? configEntry =
        isSlangYaml ? parsedYaml as YamlMap? : _findConfigEntry(parsedYaml);
    if (configEntry == null) {
      return null;
    }

    final map = MapUtils.deepCast(configEntry.value);
    return fromMap(map);
  }

  /// Returns the part of the yaml file which is "important"
  static YamlMap? _findConfigEntry(YamlMap parent) {
    for (final entry in parent.entries) {
      if (entry.key == 'slang_build_runner' && entry.value is YamlMap) {
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
    return null;
  }

  /// Parses the config entry
  static RawConfig fromMap(Map<String, dynamic> map) {
    if (map['output_format'] != null) {
      log.error(
        'The "output_format" key is no longer supported since slang v4. Always generates multiple files now.',
      );
    }

    final baseLocale = I18nLocale.fromString(
        map['base_locale'] ?? RawConfig.defaultBaseLocale);
    final keyCase =
        (map['key_case'] as String?)?.toCaseStyle() ?? RawConfig.defaultKeyCase;

    final generateEnum = map['generate_enum'] ?? RawConfig.defaultGenerateEnum;

    return RawConfig(
      baseLocale: baseLocale,
      fallbackStrategy:
          (map['fallback_strategy'] as String?)?.toFallbackStrategy() ??
              RawConfig.defaultFallbackStrategy,
      inputDirectory:
          (map['input_directory'] as String?)?.removeTrailingSlash() ??
              RawConfig.defaultInputDirectory,
      inputFilePattern:
          map['input_file_pattern'] ?? RawConfig.defaultInputFilePattern,
      outputDirectory:
          (map['output_directory'] as String?)?.removeTrailingSlash() ??
              RawConfig.defaultOutputDirectory,
      outputFileName:
          map['output_file_name'] ?? RawConfig.defaultOutputFileName,
      lazy: map['lazy'] ?? RawConfig.defaultLazy,
      localeHandling: map['locale_handling'] ?? RawConfig.defaultLocaleHandling,
      flutterIntegration:
          map['flutter_integration'] ?? RawConfig.defaultFlutterIntegration,
      namespaces: map['namespaces'] ?? RawConfig.defaultNamespaces,
      translateVar: map['translate_var'] ?? RawConfig.defaultTranslateVar,
      enumName: map['enum_name'] ?? RawConfig.defaultEnumName,
      className: map['class_name'] ?? RawConfig.defaultClassName,
      translationClassVisibility:
          (map['translation_class_visibility'] as String?)
                  ?.toTranslationClassVisibility() ??
              RawConfig.defaultTranslationClassVisibility,
      keyCase: keyCase,
      keyMapCase: (map['key_map_case'] as String?)?.toCaseStyle() ??
          RawConfig.defaultKeyMapCase,
      paramCase: (map['param_case'] as String?)?.toCaseStyle() ??
          RawConfig.defaultParamCase,
      sanitization: (map['sanitization'] as Map<String, dynamic>?)
              ?.toSanitizationConfig(
                  keyCase ?? SanitizationConfig.defaultCaseStyle) ??
          SanitizationConfig(
            enabled: SanitizationConfig.defaultEnabled,
            prefix: SanitizationConfig.defaultPrefix,
            caseStyle: keyCase ?? SanitizationConfig.defaultCaseStyle,
          ),
      stringInterpolation:
          (map['string_interpolation'] as String?)?.toStringInterpolation() ??
              RawConfig.defaultStringInterpolation,
      renderFlatMap: map['flat_map'] ?? RawConfig.defaultRenderFlatMap,
      translationOverrides:
          map['translation_overrides'] ?? RawConfig.defaultTranslationOverrides,
      renderTimestamp: map['timestamp'] ?? RawConfig.defaultRenderTimestamp,
      renderStatistics: map['statistics'] ?? RawConfig.defaultRenderStatistics,
      maps: map['maps']?.cast<String>() ?? RawConfig.defaultMaps,
      pluralAuto: (map['pluralization']?['auto'] as String?)?.toPluralAuto() ??
          RawConfig.defaultPluralAuto,
      pluralParameter:
          (map['pluralization']?['default_parameter'] as String?) ??
              RawConfig.defaultPluralParameter,
      pluralCardinal: map['pluralization']?['cardinal']?.cast<String>() ??
          RawConfig.defaultCardinal,
      pluralOrdinal: map['pluralization']?['ordinal']?.cast<String>() ??
          RawConfig.defaultOrdinal,
      contexts: (map['contexts'] as Map<String, dynamic>?)
              ?.toContextTypes(generateEnum) ??
          RawConfig.defaultContexts,
      interfaces:
          (map['interfaces'] as Map<String, dynamic>?)?.toInterfaces() ??
              RawConfig.defaultInterfaces,
      obfuscation: (map['obfuscation'] as Map<String, dynamic>?)
              ?.toObfuscationConfig() ??
          RawConfig.defaultObfuscationConfig,
      format: (map['format'] as Map<String, dynamic>?)?.toFormatConfig() ??
          RawConfig.defaultFormatConfig,
      autodoc: (map['autodoc'] as Map<String, dynamic>?)
              ?.toDocumentationConfig(baseLocale: baseLocale.languageTag) ??
          RawConfig.defaultAutodocConfig,
      imports: map['imports']?.cast<String>() ?? RawConfig.defaultImports,
      generateEnum: generateEnum,
      rawMap: map,
    );
  }
}

extension on Map<String, dynamic> {
  /// Parses the 'contexts' config
  List<ContextType> toContextTypes(bool defaultGenerateEnum) {
    return entries.map((e) {
      final enumName = e.key;
      final config = e.value as Map<String, dynamic>? ?? const {};

      return ContextType(
        enumName: enumName,
        defaultParameter:
            config['default_parameter'] ?? ContextType.DEFAULT_PARAMETER,
        generateEnum: config['generate_enum'] ?? defaultGenerateEnum,
      );
    }).toList();
  }

  /// Parses the 'interfaces' config
  List<InterfaceConfig> toInterfaces() {
    return entries.map((e) {
      final interfaceName = e.key.toCase(CaseStyle.pascal);
      final Set<InterfaceAttribute> attributes = {};
      final List<InterfacePath> paths;
      if (e.value is String) {
        // PageData: welcome.pages
        paths = [InterfacePath(e.value)];
      } else {
        // PageData:
        //   paths:
        //     - path.firstPath
        //   attributes:
        //     - String title
        //     - String? content(name)
        final interfaceConfig = e.value as Map<String, dynamic>;

        // parse attributes
        final attributesConfig = interfaceConfig['attributes'] as List? ?? {};
        for (final attribute in attributesConfig) {
          final match = RegexUtils.attributeRegex.firstMatch(attribute);
          if (match == null) {
            throw 'Interface "$interfaceName" has invalid attributes. "$attribute" could not be parsed.';
          }

          final returnType = match.group(1)!;
          final optional = match.group(3) != null;
          final attributeName = match.group(4)!;
          final parametersRaw = match.group(5);
          final Set<AttributeParameter> parameters;
          if (parametersRaw != null) {
            // remove brackets, split by comma, use Object as type
            parameters = parametersRaw
                .substring(1, parametersRaw.length - 1)
                .split(',')
                .map(
                  (p) => AttributeParameter(
                      parameterName: p.trim(), type: 'Object'),
                )
                .toSet();
          } else {
            parameters = {};
          }

          final parsedAttribute = InterfaceAttribute(
            attributeName: attributeName,
            returnType: returnType,
            parameters: parameters,
            optional: optional,
          );

          attributes.add(parsedAttribute);
        }

        // parse paths
        final pathsConfig = interfaceConfig['paths'] as List? ?? [];
        paths = pathsConfig
            .cast<String>()
            .map((path) => InterfacePath(path))
            .toList();

        if (attributes.isEmpty && paths.isEmpty) {
          throw 'Interface "$interfaceName" has no paths nor attributes.';
        }
      }

      return InterfaceConfig(
        name: interfaceName,
        attributes: attributes,
        paths: paths,
      );
    }).toList();
  }

  /// Parses the 'obfuscation' config
  ObfuscationConfig toObfuscationConfig() {
    return ObfuscationConfig.fromSecretString(
      enabled: this['enabled'] ?? ObfuscationConfig.defaultEnabled,
      secret: this['secret'],
    );
  }

  /// Parses the 'format' config
  FormatConfig toFormatConfig() {
    return FormatConfig(
      enabled: this['enabled'],
      width: this['width'],
    );
  }

  /// Parses the 'documentation' config
  AutodocConfig toDocumentationConfig({required String baseLocale}) {
    final locales = (this['locales'] as List?)?.cast<String>() ??
        AutodocConfig.defaultLocales;
    return AutodocConfig(
      enabled: this['enabled'] ?? AutodocConfig.defaultEnabled,
      locales: locales
          .map((locale) => I18nLocale.fromString(locale).languageTag)
          .toList(),
    );
  }

  /// Parses the 'sanitization' config
  SanitizationConfig toSanitizationConfig(CaseStyle fallbackCase) {
    return SanitizationConfig(
      enabled: this['enabled'] ?? SanitizationConfig.defaultEnabled,
      prefix: this['prefix'] ?? SanitizationConfig.defaultPrefix,
      caseStyle: switch (this['case'] as String?) {
        String s => s.toCaseStyle() ?? fallbackCase,
        // explicit null or not present
        null => containsKey('case') ? null : fallbackCase,
      },
    );
  }
}

extension on String {
  String removeTrailingSlash() {
    return endsWith('/') ? substring(0, length - 1) : this;
  }

  FallbackStrategy? toFallbackStrategy() {
    switch (this) {
      case 'none':
        return FallbackStrategy.none;
      case 'base_locale':
        return FallbackStrategy.baseLocale;
      case 'base_locale_empty_string':
        return FallbackStrategy.baseLocaleEmptyString;
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
}
