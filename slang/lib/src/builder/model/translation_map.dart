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
    final locales = _internalMap.keys.toList();
    final anyLanguages = _getDistinctLanguageCodes(locales);
    final anyCountries = _getDistinctCountryCodes(locales);

    for (final locale in locales) {
      if (!locale.languageIsWildcard && !locale.countryIsWildcard) {
        continue;
      }

      final translations = _internalMap.remove(locale)!;

      final List<String> languages;
      if (locale.languageIsWildcard) {
        languages = locale.language == 'any'
            ? anyLanguages.toList()
            : locale.language.split(',').map((s) => s.trim()).toList();
      } else {
        languages = [locale.language];
      }

      final List<String?> countries;
      if (locale.countryIsWildcard) {
        countries = locale.country == 'any'
            ? anyCountries.toList()
            : locale.country!.split(',').map((s) => s.trim()).toList();
      } else {
        countries = [locale.country];
      }

      for (final languageRaw in languages) {
        final parsedLanguage = I18nLocale.tryFromString(languageRaw);
        for (final country in countries) {
          final expandedLocale = I18nLocale(
            language: parsedLanguage?.language ?? languageRaw,
            script: parsedLanguage?.script ?? locale.script,
            country: parsedLanguage?.country ?? country,
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

Set<String> _getDistinctLanguageCodes(List<I18nLocale> locales) {
  final anyLanguages = <String>{};

  for (final locale in locales) {
    if (locale.languageIsWildcard) {
      if (locale.language != 'any') {
        // Language (e.g. [de,fr-FR]) may contain country,
        // we need to parse it to get the language part only
        final languages = locale.language
            .split(',')
            .map((s) => I18nLocale.tryFromString(s)?.language)
            .nonNulls;
        anyLanguages.addAll(languages);
      }
    } else {
      anyLanguages.add(locale.language);
    }
  }

  return anyLanguages;
}

Set<String> _getDistinctCountryCodes(List<I18nLocale> locales) {
  final anyCountries = <String>{};

  for (final locale in locales) {
    if (locale.languageIsWildcard && locale.language != 'any') {
      // Language (e.g. [de,fr-FR]) may contain country,
      // we need to parse it to get the country part only
      final languages = locale.language
          .split(',')
          .map((s) => I18nLocale.tryFromString(s)?.country)
          .nonNulls;
      anyCountries.addAll(languages);
    }

    if (locale.countryIsWildcard) {
      if (locale.country != 'any') {
        final countries = locale.country!.split(',').map((s) => s.trim());
        anyCountries.addAll(countries);
      }
    } else if (locale.country != null) {
      anyCountries.add(locale.country!);
    }
  }

  return anyCountries;
}
