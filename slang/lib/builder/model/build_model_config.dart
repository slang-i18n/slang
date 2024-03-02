import 'package:slang/builder/model/context_type.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/interface.dart';
import 'package:slang/builder/model/raw_config.dart';

/// Config to generate the model.
/// A subset of [RawConfig].
class BuildModelConfig {
  final FallbackStrategy fallbackStrategy;
  final CaseStyle? keyCase;
  final CaseStyle? keyMapCase;
  final CaseStyle? paramCase;
  final StringInterpolation stringInterpolation;
  final List<String> maps;
  final PluralAuto pluralAuto;
  final String pluralParameter;
  final List<String> pluralCardinal;
  final List<String> pluralOrdinal;
  final List<ContextType> contexts;
  final List<InterfaceConfig> interfaces;

  BuildModelConfig({
    required this.fallbackStrategy,
    required this.keyCase,
    required this.keyMapCase,
    required this.paramCase,
    required this.stringInterpolation,
    required this.maps,
    required this.pluralAuto,
    required this.pluralParameter,
    required this.pluralCardinal,
    required this.pluralOrdinal,
    required this.contexts,
    required this.interfaces,
  });
}
