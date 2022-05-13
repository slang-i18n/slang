import 'package:slang/builder/model/build_config.dart';
import 'package:slang/builder/model/context_type.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/interface.dart';
import 'package:slang/builder/utils/regex_utils.dart';
import 'package:slang/builder/utils/string_extensions.dart';
import 'package:slang/builder/utils/yaml_utils.dart';
import 'package:yaml/yaml.dart';

class BuildConfigBuilder {
  /// Parses the full build.yaml file to get the config
  /// May return null if no config entry is found.
  static BuildConfig? fromYaml(String rawYaml) {
    final parsedYaml = loadYaml(rawYaml);
    final configEntry = _findConfigEntry(parsedYaml);
    if (configEntry == null) {
      return null;
    }

    final map = YamlUtils.deepCast(configEntry.value);
    return fromMap(map);
  }

  /// Returns the part of the yaml file which is "important"
  static YamlMap? _findConfigEntry(YamlMap parent) {
    for (final entry in parent.entries) {
      if (entry.key == 'slang' && entry.value is YamlMap) {
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
  static BuildConfig fromMap(Map<String, dynamic> map) {
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
      outputFileName:
          map['output_file_name'] ?? BuildConfig.defaultOutputFileName,
      outputFormat: (map['output_format'] as String?)?.toOutputFormat() ??
          BuildConfig.defaultOutputFormat,
      localeHandling:
          map['locale_handling'] ?? BuildConfig.defaultLocaleHandling,
      flutterIntegration:
          map['flutter_integration'] ?? BuildConfig.defaultFlutterIntegration,
      namespaces: map['namespaces'] ?? BuildConfig.defaultNamespaces,
      translateVar: map['translate_var'] ?? BuildConfig.defaultTranslateVar,
      enumName: map['enum_name'] ?? BuildConfig.defaultEnumName,
      translationClassVisibility:
          (map['translation_class_visibility'] as String?)
                  ?.toTranslationClassVisibility() ??
              BuildConfig.defaultTranslationClassVisibility,
      keyCase: (map['key_case'] as String?)?.toCaseStyle() ??
          BuildConfig.defaultKeyCase,
      keyMapCase: (map['key_map_case'] as String?)?.toCaseStyle() ??
          BuildConfig.defaultKeyMapCase,
      paramCase: (map['param_case'] as String?)?.toCaseStyle() ??
          BuildConfig.defaultParamCase,
      stringInterpolation:
          (map['string_interpolation'] as String?)?.toStringInterpolation() ??
              BuildConfig.defaultStringInterpolation,
      renderFlatMap: map['flat_map'] ?? BuildConfig.defaultRenderFlatMap,
      renderTimestamp: map['timestamp'] ?? BuildConfig.defaultRenderTimestamp,
      maps: map['maps']?.cast<String>() ?? BuildConfig.defaultMaps,
      pluralAuto: (map['pluralization']?['auto'] as String?)?.toPluralAuto() ??
          BuildConfig.defaultPluralAuto,
      pluralCardinal: map['pluralization']?['cardinal']?.cast<String>() ??
          BuildConfig.defaultCardinal,
      pluralOrdinal: map['pluralization']?['ordinal']?.cast<String>() ??
          BuildConfig.defaultOrdinal,
      contexts: (map['contexts'] as Map<String, dynamic>?)?.toContextTypes() ??
          BuildConfig.defaultContexts,
      interfaces:
          (map['interfaces'] as Map<String, dynamic>?)?.toInterfaces() ??
              BuildConfig.defaultInterfaces,
    );
  }
}

extension on Map<String, dynamic> {
  /// Parses the 'contexts' config
  List<ContextType> toContextTypes() {
    return this.entries.map((e) {
      final enumName = e.key.toCase(CaseStyle.pascal);
      final config = e.value as Map<String, dynamic>;

      return ContextType(
        enumName: enumName,
        enumValues: (config['enum'].cast<String>() as List<String>)
            .map((e) => e.toCase(CaseStyle.camel))
            .toList(),
        auto: config['auto'] ?? ContextType.defaultAuto,
        paths: config['paths']?.cast<String>() ?? ContextType.defaultPaths,
      );
    }).toList();
  }

  /// Parses the 'interfaces' config
  List<InterfaceConfig> toInterfaces() {
    return this.entries.map((e) {
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
        attributesConfig.forEach((attribute) {
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
        });

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
}
