import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';

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
    String namespace = RegexUtils.defaultNamespace,
    required Map<String, dynamic> translations,
  }) {
    final Map<String, Map<String, dynamic>> namespaceMap;
    if (_internalMap.containsKey(locale)) {
      namespaceMap = _internalMap[locale]!;
    } else {
      // ensure that the locale exists
      namespaceMap = {};
      _internalMap[locale] = namespaceMap;
    }

    namespaceMap[namespace] = translations;

    // Copy types of each namespace to the global types map,
    // merging them with existing types.
    final typesMap = translations['@@types'] as Map<String, dynamic>?;
    if (typesMap != null) {
      namespaceMap['@@types'] = {
        ...?namespaceMap['@@types'],
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
