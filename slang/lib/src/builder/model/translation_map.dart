import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';

/// Contains ALL translations of ALL locales
/// Represented as pure maps without modifications
///
/// locale -> (namespace -> translation map)
class TranslationMap {
  final _internalMap = <I18nLocale, FlatNamespaceMap>{};

  TranslationMap();

  TranslationMap.fromMap(
    Map<I18nLocale, Map<String, Map<String, dynamic>>> map,
  ) {
    for (final entry in map.entries) {
      _internalMap[entry.key] = FlatNamespaceMap(entry.value);
    }
  }

  /// Read access
  FlatNamespaceMap? operator [](I18nLocale key) {
    return _internalMap[key];
  }

  /// Add a namespace and its translations
  /// Namespace may be ignored if this feature is not used
  void addTranslations({
    required I18nLocale locale,
    String namespace = RegexUtils.defaultNamespace,
    required Map<String, dynamic> translations,
  }) {
    final FlatNamespaceMap namespaceMap;
    if (_internalMap.containsKey(locale)) {
      namespaceMap = _internalMap[locale]!;
    } else {
      // ensure that the locale exists
      namespaceMap = FlatNamespaceMap({});
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

  /// Expands wildcard locales (e.g. `[de,en]-US`, `[any]-US`) into concrete
  /// locales. Should be called after all translations have been added.
  /// Existing explicit locales are extended with the wildcard translations;
  /// keys already defined on the explicit locale take precedence.
  void finalize() {
    final wildcards =
        _internalMap.keys.where((l) => l.languageIsWildcard).toList();
    if (wildcards.isEmpty) {
      return;
    }

    final anyLanguages = _internalMap.keys
        .where((l) => !l.languageIsWildcard)
        .map((l) => l.language)
        .toSet();

    for (final wildcard in wildcards) {
      if (wildcard.languageIsWildcard && wildcard.language != 'any') {
        final languages = wildcard.language.split(',').map((s) => s.trim());
        anyLanguages.addAll(languages);
      }
    }

    for (final wildcard in wildcards) {
      final translations = _internalMap.remove(wildcard)!;

      final languages = wildcard.language == 'any'
          ? anyLanguages
          : wildcard.language.split(',').map((s) => s.trim()).toList();

      for (final language in languages) {
        final expandedLocale = I18nLocale(
          language: language,
          script: wildcard.script,
          country: wildcard.country,
          generatedFromWildcard: true,
        );
        final existing = _internalMap[expandedLocale];
        if (existing == null) {
          _internalMap[expandedLocale] = translations;
        } else {
          _internalMap[expandedLocale] = FlatNamespaceMap(
            MapUtils.merge(
              base: translations,
              other: existing,
            ).cast<String, Map<String, dynamic>>(),
          );
        }
      }
    }
  }

  /// Return all locales specified in this map
  List<I18nLocale> getLocales() {
    return _internalMap.keys.toList();
  }

  Map<I18nLocale, FlatNamespaceMap> getInternalMap() {
    return _internalMap;
  }
}

extension type FlatNamespaceMap(Map<String, Map<String, dynamic>> m)
    implements Map<String, Map<String, dynamic>> {
  ExpandedNamespaceMap expand() {
    ExpandedNamespaceMap curr = ExpandedNamespaceMap(this);

    if (keys.any((k) => k.contains('.'))) {
      // Has dot-separated keys, we need to build the nested structure
      final result = ExpandedNamespaceMap({});
      for (final entry in entries) {
        final parts = entry.key.split('.');
        if (parts.length == 1) {
          result[entry.key] = {...entry.value};
        } else {
          Map<String, dynamic> current = result.putIfAbsent(
            parts.first,
            () => <String, dynamic>{},
          );
          for (int i = 1; i < parts.length - 1; i++) {
            final nested = current.putIfAbsent(
              parts[i],
              () => <String, dynamic>{},
            ) as Map<String, dynamic>;
            current = nested;
          }
          current[parts.last] = {...entry.value};
        }
      }
      curr = result;
    }

    if (containsKey(RegexUtils.defaultNamespace)) {
      curr = ExpandedNamespaceMap({
        ...this[RegexUtils.defaultNamespace]!,
        ...{
          for (final entry in curr.entries)
            if (entry.key != RegexUtils.defaultNamespace)
              entry.key: entry.value,
        },
      });
    }

    return curr;
  }
}

extension type ExpandedNamespaceMap(Map<String, dynamic> m)
    implements Map<String, dynamic> {
  FlatNamespaceMap flatten({required Set<String> namespaces}) {
    final result = <String, Map<String, dynamic>>{};

    // Collect top-level namespace names
    final topLevelNamespaces =
        namespaces.map((n) => n.split('.').first).toSet();

    // Collect default namespace entries (top-level keys not in any namespace)
    final defaultEntries = <String, dynamic>{
      for (final entry in entries)
        if (!topLevelNamespaces.contains(entry.key)) entry.key: entry.value,
    };
    if (defaultEntries.isNotEmpty) {
      result[RegexUtils.defaultNamespace] = defaultEntries;
    }

    // Collect each namespace
    for (final namespace in namespaces) {
      final parts = namespace.split('.');
      Map<String, dynamic>? current = this;
      for (final part in parts) {
        final value = current?[part];
        if (value is Map<String, dynamic>) {
          current = value;
        } else {
          current = null;
          break;
        }
      }

      if (current != null) {
        // Remove sub-namespace keys from this level
        final subNamespaceKeys = namespaces
            .where((n) => n.startsWith('$namespace.'))
            .map((n) => n.substring(namespace.length + 1).split('.').first)
            .toSet();

        result[namespace] = <String, dynamic>{
          for (final entry in current.entries)
            if (!subNamespaceKeys.contains(entry.key)) entry.key: entry.value,
        };
      }
    }

    return FlatNamespaceMap(result);
  }
}
