import 'package:slang/builder/model/build_model_config.dart';
import 'package:slang/builder/model/raw_config.dart';

extension BuildModelConfigBuilder on RawConfig {
  BuildModelConfig toBuildModelConfig() {
    return BuildModelConfig(
      baseLocale: baseLocale,
      fallbackStrategy: fallbackStrategy,
      keyCase: keyCase,
      keyMapCase: keyMapCase,
      paramCase: paramCase,
      stringInterpolation: stringInterpolation,
      maps: maps,
      pluralAuto: pluralAuto,
      pluralCardinal: pluralCardinal,
      pluralOrdinal: pluralOrdinal,
      contexts: contexts,
      interfaces: interfaces,
    );
  }
}
