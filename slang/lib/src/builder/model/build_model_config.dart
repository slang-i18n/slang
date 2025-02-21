import 'package:slang/src/builder/model/context_type.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/interface.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/sanitization_config.dart';

/// Config to generate the model.
/// A subset of [RawConfig].
class BuildModelConfig {
  final FallbackStrategy fallbackStrategy;
  final CaseStyle? keyCase;
  final CaseStyle? keyMapCase;
  final CaseStyle? paramCase;
  final SanitizationConfig sanitization;
  final StringInterpolation stringInterpolation;
  final List<String> maps;
  final PluralAuto pluralAuto;
  final String pluralParameter;
  final List<String> pluralCardinal;
  final List<String> pluralOrdinal;
  final List<ContextType> contexts;
  final List<InterfaceConfig> interfaces;
  final bool generateEnum;

  BuildModelConfig({
    required this.fallbackStrategy,
    required this.keyCase,
    required this.keyMapCase,
    required this.paramCase,
    required this.sanitization,
    required this.stringInterpolation,
    required this.maps,
    required this.pluralAuto,
    required this.pluralParameter,
    required this.pluralCardinal,
    required this.pluralOrdinal,
    required this.contexts,
    required this.interfaces,
    required this.generateEnum,
  });
}
