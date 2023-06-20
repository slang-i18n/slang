import 'package:slang/builder/model/i18n_locale.dart';

/// Contains ALL translations of ALL locales
/// Represented as pure maps without modifications
///
/// locale -> (namespace -> translation map)
class TranslationMap {
  final _internalMap = <I18nLocale, Map<String, Map<String, dynamic>>>{};

  /// Read access
  Map<String, Map<String, dynamic>>? operator [](I18nLocale key) {
    return _internalMap[key];
  }

  /// Add a namespace and its translations
  /// Namespace may be ignored if this feature is not used
  void addTranslations({
    required I18nLocale locale,
    String namespace = 'not relevant',
    required Map<String, dynamic> translations,
  }) {
    if (!_internalMap.containsKey(locale)) {
      // ensure that the locale exists
      _internalMap[locale] = {};
    }

    _internalMap[locale]![namespace] = translations;
  }

  /// Return all locales specified in this map
  List<I18nLocale> getLocales() {
    return _internalMap.keys.toList();
  }

  Map<I18nLocale, Map<String, Map<String, dynamic>>> getInternalMap() {
    return _internalMap;
  }
}
