import 'package:slang/src/builder/model/i18n_locale.dart';

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

    // Copy types of each namespace to the global types map,
    // merging them with existing types.
    final typesMap = translations['@@types'] as Map<String, dynamic>?;
    if (typesMap != null) {
      _internalMap[locale]!['@@types'] = {
        ...?_internalMap[locale]!['@@types'],
        ...typesMap,
      };
    }
  }

  /// Return all locales specified in this map
  List<I18nLocale> getLocales() {
    return _internalMap.keys.toList();
  }

  Map<I18nLocale, Map<String, Map<String, dynamic>>> getInternalMap() {
    return _internalMap;
  }
}
