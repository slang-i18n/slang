import 'package:slang/src/builder/model/autodoc_config.dart';
import 'package:slang/src/builder/model/build_model_config.dart';
import 'package:slang/src/builder/model/context_type.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/format_config.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/interface.dart';
import 'package:slang/src/builder/model/obfuscation_config.dart';

/// Config for the generation step (generate dart-content from model)
/// Applies to all locales
class GenerateConfig {
  final BuildModelConfig buildConfig; // for translation overrides
  final String inputDirectoryHint; // for comment
  final I18nLocale baseLocale; // defaults to 'en'
  final GenerateFallbackStrategy fallbackStrategy;
  final String outputFileName;
  final bool lazy;
  final bool localeHandling;
  final bool flutterIntegration;
  final String translateVariable;
  final String enumName;
  final String className;
  final TranslationClassVisibility translationClassVisibility;
  final bool renderFlatMap;
  final bool translationOverrides;
  final bool renderTimestamp;
  final bool renderStatistics;
  final List<PopulatedContextType> contexts;
  final List<Interface> interface; // may include more than in build config
  final ObfuscationConfig obfuscation;
  final FormatConfig format;
  final AutodocConfig autodoc;
  final List<String> imports;

  GenerateConfig({
    required this.buildConfig,
    required this.inputDirectoryHint,
    required this.baseLocale,
    required this.fallbackStrategy,
    required this.outputFileName,
    required this.lazy,
    required this.localeHandling,
    required this.flutterIntegration,
    required this.translateVariable,
    required this.enumName,
    required this.className,
    required this.translationClassVisibility,
    required this.renderFlatMap,
    required this.translationOverrides,
    required this.renderTimestamp,
    required this.renderStatistics,
    required this.contexts,
    required this.interface,
    required this.obfuscation,
    required this.format,
    required this.autodoc,
    required this.imports,
  });
}
