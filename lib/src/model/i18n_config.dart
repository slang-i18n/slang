import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/pluralization.dart';

/// general config, applies to all locales
class I18nConfig {
  final bool nullSafety; // whether or not apply new null safety version
  final String baseName; // name of all i18n files, like strings or messages
  final I18nLocale baseLocale; // defaults to 'en'
  final FallbackStrategy fallbackStrategy;
  final List<PluralizationResolver> renderedPluralizationResolvers;
  final KeyCase? keyCase;
  final String translateVariable;
  final String enumName;
  final TranslationClassVisibility translationClassVisibility;
  final bool renderFlatMap;

  I18nConfig({
    required this.nullSafety,
    required this.baseName,
    required this.baseLocale,
    required this.fallbackStrategy,
    required this.renderedPluralizationResolvers,
    required this.keyCase,
    required this.translateVariable,
    required this.enumName,
    required this.translationClassVisibility,
    required this.renderFlatMap,
  });
}
