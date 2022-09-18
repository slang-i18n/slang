import 'package:slang/builder/builder/translation_model_builder.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/interface.dart';
import 'package:slang/builder/model/node.dart';

typedef I18nDataComparator = int Function(I18nData a, I18nData b);

/// represents one locale and its localized strings
class I18nData {
  final bool base; // whether or not this is the base locale
  final I18nLocale locale; // the locale (the part after the underscore)
  final ObjectNode root; // the actual strings
  final List<Interface> interfaces;

  I18nData({
    required this.base,
    required this.locale,
    required this.root,
    required this.interfaces,
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

extension I18nBuilderExt on BuildModelResult {
  I18nData toI18nData({
    required bool base,
    required I18nLocale locale,
  }) {
    return I18nData(
      base: base,
      locale: locale,
      root: root,
      interfaces: interfaces,
    );
  }
}
