import 'package:slang/builder/builder/build_model_config_builder.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/generate_config.dart';
import 'package:slang/builder/model/interface.dart';

class GenerateConfigBuilder {
  static GenerateConfig build({
    required String baseName,
    required RawConfig config,
    required List<Interface> interfaces,
  }) {
    return GenerateConfig(
      buildConfig: config.toBuildModelConfig(),
      baseName: baseName,
      baseLocale: config.baseLocale,
      fallbackStrategy: config.fallbackStrategy,
      outputFormat: config.outputFormat,
      localeHandling: config.localeHandling,
      flutterIntegration: config.flutterIntegration,
      translateVariable: config.translateVar,
      enumName: config.enumName,
      translationClassVisibility: config.translationClassVisibility,
      renderFlatMap: config.renderFlatMap,
      translationOverrides: config.translationOverrides,
      renderTimestamp: config.renderTimestamp,
      contexts: config.contexts,
      interface: interfaces,
      obfuscation: config.obfuscation,
      imports: config.imports,
    );
  }
}
