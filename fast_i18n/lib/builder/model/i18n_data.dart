import 'package:fast_i18n/builder/model/i18n_locale.dart';
import 'package:fast_i18n/builder/model/interface.dart';
import 'package:fast_i18n/builder/model/node.dart';

typedef int I18nDataComparator(I18nData a, I18nData b);

/// represents one locale and its localized strings
class I18nData {
  final bool base; // whether or not this is the base locale
  final I18nLocale locale; // the locale (the part after the underscore)
  final ObjectNode root; // the actual strings
  final List<Interface> interfaces;
  final bool hasCardinal;
  final bool hasOrdinal;

  I18nData({
    required this.base,
    required this.locale,
    required this.root,
    required this.interfaces,
    required this.hasCardinal,
    required this.hasOrdinal,
  });

  /// sorts base locale first, then alphabetically
  static I18nDataComparator generationComparator = (I18nData a, I18nData b) {
    if (!a.base && !b.base) {
      return a.locale.languageTag.compareTo(b.locale.languageTag);
    } else if (!a.base && b.base) {
      return 1; // move non-base to the right
    } else {
      return -1; // move base to the left
    }
  };
}
