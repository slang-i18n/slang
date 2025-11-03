import 'package:slang/src/builder/builder/build_model_config_builder.dart';
import 'package:slang/src/builder/model/context_type.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/generate_config.dart';
import 'package:slang/src/builder/model/interface.dart';
import 'package:slang/src/builder/model/raw_config.dart';

class GenerateConfigBuilder {
  static GenerateConfig build({
    required RawConfig config,
    required String inputDirectoryHint,
    required List<PopulatedContextType> contexts,
    required List<Interface> interfaces,
  }) {
    return GenerateConfig(
      buildConfig: config.toBuildModelConfig(),
      inputDirectoryHint: inputDirectoryHint,
      baseLocale: config.baseLocale,
      fallbackStrategy: config.fallbackStrategy.toGenerateFallbackStrategy(),
      outputFileName: config.outputFileName,
      lazy: config.lazy,
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
      contexts: contexts,
      interface: interfaces,
      obfuscation: config.obfuscation,
      format: config.format,
      autodoc: config.autodoc,
      imports: config.imports,
    );
  }
}
