import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/context_type.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/pluralization.dart';

/// general config, applies to all locales
class I18nConfig {
  final String baseName; // name of all i18n files, like strings or messages
  final I18nLocale baseLocale; // defaults to 'en'
  final FallbackStrategy fallbackStrategy;
  final List<PluralizationResolver> renderedPluralizationResolvers;
  final String translateVariable;
  final String enumName;
  final TranslationClassVisibility translationClassVisibility;
  final bool renderFlatMap;
  final List<ContextType> contexts;

  I18nConfig({
    required this.baseName,
    required this.baseLocale,
    required this.fallbackStrategy,
    required this.renderedPluralizationResolvers,
    required this.translateVariable,
    required this.enumName,
    required this.translationClassVisibility,
    required this.renderFlatMap,
    required this.contexts,
  });
}
