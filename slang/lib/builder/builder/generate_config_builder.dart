import 'package:slang/builder/builder/build_model_config_builder.dart';
import 'package:slang/builder/model/context_type.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/generate_config.dart';
import 'package:slang/builder/model/interface.dart';

class GenerateConfigBuilder {
  static GenerateConfig build({
    required String baseName,
    required RawConfig config,
    required String inputDirectoryHint,
    required List<ContextType> contexts,
    required List<Interface> interfaces,
  }) {
    return GenerateConfig(
      buildConfig: config.toBuildModelConfig(),
      inputDirectoryHint: inputDirectoryHint,
      baseName: baseName,
      baseLocale: config.baseLocale,
      fallbackStrategy: config.fallbackStrategy.toGenerateFallbackStrategy(),
      outputFileName: config.outputFileName,
      outputFormat: config.outputFormat,
      localeHandling: config.localeHandling,
      flutterIntegration: config.flutterIntegration,
      translateVariable: config.translateVar,
      enumName: config.enumName,
      className: config.className,
      translationClassVisibility: config.translationClassVisibility,
      renderFlatMap: config.renderFlatMap,
      translationOverrides: config.translationOverrides,
      renderTimestamp: config.renderTimestamp,
      renderStatistics: config.renderStatistics,
      contexts: contexts.map((c) {
        return PopulatedContextType(
          enumName: c.enumName,
          enumValues: c.enumValues!,
          generateEnum: c.generateEnum,
        );
      }).toList(),
      interface: interfaces,
      obfuscation: config.obfuscation,
      imports: config.imports,
    );
  }
}
