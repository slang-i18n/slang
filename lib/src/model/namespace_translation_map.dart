import 'package:fast_i18n/src/model/i18n_locale.dart';

/// Used during the read step of all translation assets
///
/// locale -> (namespace -> translation map)
class NamespaceTranslationMap {
  final _internalMap = <I18nLocale, Map<String, Map<String, dynamic>>>{};

  /// Add a namespace and its translations
  void add({
    required I18nLocale locale,
    required String namespace,
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
