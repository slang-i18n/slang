import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/node.dart';

typedef int I18nDataComparator(I18nData a, I18nData b);

/// represents one locale and its localized strings
class I18nData {
  final bool base; // whether or not this is the base locale
  final I18nLocale locale; // the locale (the part after the underscore)
  final String localeTag; // the locale code tag
  final ObjectNode root; // the actual strings

  I18nData({this.base, this.locale, this.root})
      : localeTag = locale.toLanguageTag();

  /// sorts base locale first, then alphabetically
  static I18nDataComparator generationComparator = (I18nData a, I18nData b) {
    if (!a.base && !b.base) {
      return a.localeTag.compareTo(b.localeTag);
    } else if (!a.base && b.base) {
      return 1; // move non-base to the right
    } else {
      return -1; // move base to the left
    }
  };
}
