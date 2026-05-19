import 'package:slang/src/builder/builder/build_model_config_builder.dart';
import 'package:slang/src/builder/builder/translation_model_builder.dart';
import 'package:slang/src/builder/model/i18n_data.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';

class TranslationModelListBuilder {
  /// Combine all namespaces and build the internal model
  /// The returned locales are sorted (base locale first)
  ///
  /// After this method call, information about the namespace is lost.
  /// It will be just a normal parent.
  static List<I18nData> build(
    RawConfig rawConfig,
    TranslationMap translationMap,
  ) {
    final buildConfig = rawConfig.toBuildModelConfig();

    // Detect region locales (file names like _TR.i18n.json) and separate them
    // from normal locales. Region locales provide country-specific overrides
    // (e.g., currency) and are merged into composed language-country locales.
    final regionData = _extractRegionData(translationMap);

    // Compose language+region locales for every combination that doesn't
    // already have an explicit file.  e.g. fr + _TR → fr-TR.
    if (regionData.isNotEmpty) {
      _composeRegionLocales(translationMap, regionData);
    }

    final baseEntry = translationMap.getInternalMap().entries.firstWhere(
          (entry) => entry.key == rawConfig.baseLocale,
          orElse: () => throw Exception('Base locale not found'),
        );

    // Create the base data first.
    final namespaces = baseEntry.value;
    final baseResult = TranslationModelBuilder.build(
      buildConfig: buildConfig,
      map: rawConfig.namespaces ? namespaces.digest() : namespaces.values.first,
      locale: baseEntry.key,
    );

    return translationMap.getInternalMap().entries.map((localeEntry) {
      final locale = localeEntry.key;
      final namespaces = localeEntry.value;
      final base = locale == rawConfig.baseLocale;

      if (base) {
        // Use the already computed base data
        return I18nData(
          base: true,
          locale: locale,
          root: baseResult.root,
          contexts: baseResult.contexts,
          interfaces: baseResult.interfaces,
          types: baseResult.types,
        );
      } else {
        final result = TranslationModelBuilder.build(
          buildConfig: buildConfig,
          map: rawConfig.namespaces
              ? namespaces.digest()
              : namespaces.values.first,
          baseData: baseResult,
          locale: locale,
        );

        return I18nData(
          base: false,
          locale: locale,
          root: result.root,
          contexts: result.contexts,
          interfaces: result.interfaces,
          types: result.types,
        );
      }
    }).toList()
      ..sort(I18nData.generationComparator);
  }

  /// Extracts region locales (languageTag starting with '_') from the
  /// translation map, removes them so they don't get standalone classes,
  /// and returns their data keyed by region code (e.g. 'TR', 'DE').
  static Map<String, Map<String, dynamic>> _extractRegionData(
      TranslationMap translationMap) {
    final result = <String, Map<String, dynamic>>{};
    final toRemove = <I18nLocale>[];

    for (final entry in translationMap.getInternalMap().entries) {
      final tag = entry.key.languageTag;
      if (tag.startsWith('_') && tag.length > 1) {
        final regionCode = tag.substring(1); // e.g. '_TR' → 'TR'
        final namespaces = entry.value;
        result[regionCode] = namespaces.containsKey(RegexUtils.defaultNamespace)
            ? namespaces[RegexUtils.defaultNamespace]!
            : namespaces.values.first;
        toRemove.add(entry.key);
      }
    }

    for (final locale in toRemove) {
      translationMap.getInternalMap().remove(locale);
    }

    return result;
  }

  /// For each language locale and each region, creates a composed
  /// language-REGION locale if one doesn't already exist explicitly.
  /// Only the region-specific overrides are stored; language keys are
  /// inherited via cascade `extends`.
  static void _composeRegionLocales(
      TranslationMap translationMap,
      Map<String, Map<String, dynamic>> regionData,
  ) {
    final languageTags = translationMap
        .getInternalMap()
        .keys
        .map((l) => l.languageTag)
        .toSet();
    final existingTags = languageTags.toSet();

    for (final langTag in languageTags) {
      final langLocale = I18nLocale.fromString(langTag);
      // Only compose from pure language locales (no country, no script).
      if (langLocale.country != null || langLocale.script != null) {
        continue;
      }

      for (final regionEntry in regionData.entries) {
        final composedTag = '$langTag-${regionEntry.key}';
        if (existingTags.contains(composedTag)) continue;

        // Only store region overrides; language keys are inherited from parent.
        translationMap.addTranslations(
          locale: I18nLocale.fromString(composedTag),
          translations: regionEntry.value,
        );
      }
    }
  }
}

extension on Map<String, Map<String, dynamic>> {
  Map<String, dynamic> digest() {
    Map<String, dynamic> curr = this;

    if (keys.any((k) => k.contains('.'))) {
      // Has dot-separated keys, we need to build the nested structure
      final result = <String, Map<String, dynamic>>{};
      for (final entry in entries) {
        final parts = entry.key.split('.');
        if (parts.length == 1) {
          result[entry.key] = entry.value;
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
          current[parts.last] = entry.value;
        }
      }
      curr = result;
    }

    if (length > 1 && containsKey(RegexUtils.defaultNamespace)) {
      curr = {
        ...this[RegexUtils.defaultNamespace]!,
        ...{
          for (final entry in curr.entries)
            if (entry.key != RegexUtils.defaultNamespace)
              entry.key: entry.value,
        },
      };
    }

    return curr;
  }
}