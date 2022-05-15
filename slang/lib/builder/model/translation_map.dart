import 'package:slang/builder/model/i18n_locale.dart';

/// Contains ALL translations of ALL locales
/// Represented as pure maps without modifications
///
/// locale -> (namespace -> translation map)
class TranslationMap {
  final _internalMap = <I18nLocale, Map<String, Map<String, dynamic>>>{};

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

  /// Get all entries
  Iterable<MapEntry<I18nLocale, Map<String, Map<String, dynamic>>>>
      getEntries() {
    return _internalMap.entries;
  }
}
