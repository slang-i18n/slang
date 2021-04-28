import 'package:fast_i18n/src/model/i18n_locale.dart';

/// general config, applies to all locales
class I18nConfig {
  final String baseName; // name of all i18n files, like strings or messages
  final I18nLocale baseLocale; // defaults to 'en'
  final KeyCase? keyCase;
  final String translateVariable;
  final String enumName;
  final TranslationClassVisibility translationClassVisibility;

  I18nConfig(
      {required this.baseName,
      required this.baseLocale,
      required this.keyCase,
      required this.translateVariable,
      required this.enumName,
      required this.translationClassVisibility});
}

enum TranslationClassVisibility { private, public }
enum KeyCase { camel, pascal, snake }

extension Parser on String? {
  KeyCase? toKeyCase() {
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

  TranslationClassVisibility? toTranslationClassVisibility() {
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
