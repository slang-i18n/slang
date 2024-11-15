import 'package:slang/src/builder/model/build_model_config.dart';
import 'package:slang/src/builder/model/raw_config.dart';

extension BuildModelConfigBuilder on RawConfig {
  BuildModelConfig toBuildModelConfig() {
    return BuildModelConfig(
      fallbackStrategy: fallbackStrategy,
      keyCase: keyCase,
      keyMapCase: keyMapCase,
      paramCase: paramCase,
      sanitization: sanitization,
      stringInterpolation: stringInterpolation,
      maps: maps,
      pluralAuto: pluralAuto,
      pluralParameter: pluralParameter,
      pluralCardinal: pluralCardinal,
      pluralOrdinal: pluralOrdinal,
      contexts: contexts,
      interfaces: interfaces,
    );
  }
}
