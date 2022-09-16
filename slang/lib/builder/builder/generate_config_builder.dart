import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/generate_config.dart';
import 'package:slang/builder/model/interface.dart';

class GenerateConfigBuilder {
  static GenerateConfig build({
    required String baseName,
    required RawConfig buildConfig,
    required List<Interface> interfaces,
  }) {
    return GenerateConfig(
      baseName: baseName,
      baseLocale: buildConfig.baseLocale,
      fallbackStrategy: buildConfig.fallbackStrategy,
      outputFormat: buildConfig.outputFormat,
      localeHandling: buildConfig.localeHandling,
      flutterIntegration: buildConfig.flutterIntegration,
      translateVariable: buildConfig.translateVar,
      enumName: buildConfig.enumName,
      translationClassVisibility: buildConfig.translationClassVisibility,
      renderFlatMap: buildConfig.renderFlatMap,
      renderTimestamp: buildConfig.renderTimestamp,
      contexts: buildConfig.contexts,
      interface: interfaces,
      imports: buildConfig.imports,
    );
  }
}
