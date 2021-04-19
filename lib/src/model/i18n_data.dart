import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/node.dart';

/// represents one locale and its localized strings
class I18nData {
  final bool base; // whether or not this is the base locale
  final I18nLocale locale; // the locale (the part after the underscore)
  final String localeTag; // the locale code tag
  final ObjectNode root; // the actual strings

  I18nData({required this.base, required this.locale, required this.root})
      : localeTag = locale.toLanguageTag();
}
