import 'package:slang/builder/model/context_type.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/interface.dart';
import 'package:slang/builder/model/obfuscation_config.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';
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
    return RawConfig(
      baseLocale: I18nLocale.fromString(
          map['base_locale'] ?? RawConfig.defaultBaseLocale),
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
      outputFormat: (map['output_format'] as String?)?.toOutputFormat() ??
          RawConfig.defaultOutputFormat,
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
      keyCase: (map['key_case'] as String?)?.toCaseStyle() ??
          RawConfig.defaultKeyCase,
      keyMapCase: (map['key_map_case'] as String?)?.toCaseStyle() ??
          RawConfig.defaultKeyMapCase,
      paramCase: (map['param_case'] as String?)?.toCaseStyle() ??
          RawConfig.defaultParamCase,
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
      contexts: (map['contexts'] as Map<String, dynamic>?)?.toContextTypes() ??
          RawConfig.defaultContexts,
      interfaces:
          (map['interfaces'] as Map<String, dynamic>?)?.toInterfaces() ??
              RawConfig.defaultInterfaces,
      obfuscation: (map['obfuscation'] as Map<String, dynamic>?)
              ?.toObfuscationConfig() ??
          RawConfig.defaultObfuscationConfig,
      imports: map['imports']?.cast<String>() ?? RawConfig.defaultImports,
      rawMap: map,
    );
  }
}

extension on Map<String, dynamic> {
  /// Parses the 'contexts' config
  List<ContextType> toContextTypes() {
    return entries.map((e) {
      final enumName = e.key.toCase(CaseStyle.pascal);
      final config = e.value as Map<String, dynamic>;

      if (config['auto'] != null) {
        print('context "auto" config is redundant. Remove it.');
      }

      return ContextType(
        enumName: enumName,
        enumValues: config['enum']?.cast<String>(),
        paths: config['paths']?.cast<String>() ?? ContextType.defaultPaths,
        defaultParameter:
            config['default_parameter'] ?? ContextType.DEFAULT_PARAMETER,
        generateEnum:
            config['generate_enum'] ?? ContextType.defaultGenerateEnum,
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
}

extension on String {
  String removeTrailingSlash() {
    return endsWith('/') ? substring(0, length - 1) : this;
  }
}
