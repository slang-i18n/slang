import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/pluralization.dart';

/// general config, applies to all locales
class I18nConfig {
  final bool nullSafety; // whether or not apply new null safety version
  final String baseName; // name of all i18n files, like strings or messages
  final I18nLocale baseLocale; // defaults to 'en'
  final List<PluralizationResolver> renderedPluralizationResolvers;
  final KeyCase keyCase;
  final String translateVariable;
  final String enumName;
  final TranslationClassVisibility translationClassVisibility;

  I18nConfig(
      {this.nullSafety,
      this.baseName,
      this.baseLocale,
      this.renderedPluralizationResolvers,
      this.keyCase,
      this.translateVariable,
      this.enumName,
      this.translationClassVisibility});
}

enum TranslationClassVisibility { private, public }
enum KeyCase { camel, pascal, snake }

extension Parser on String {
  KeyCase toKeyCase() {
    switch (this) {
      case 'camel':
        return KeyCase.camel;
      case 'snake':
        return KeyCase.snake;
      case 'pascal':
        return KeyCase.pascal;
      default:
        return null;
    }
  }

  TranslationClassVisibility toTranslationClassVisibility() {
    switch (this) {
      case 'private':
        return TranslationClassVisibility.private;
      case 'public':
        return TranslationClassVisibility.public;
      default:
        return null;
    }
  }
}
