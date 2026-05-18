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

      final langNamespaces =
          translationMap.getInternalMap()[langLocale]!;
      final langTranslations = langNamespaces
              .containsKey(RegexUtils.defaultNamespace)
          ? Map<String, dynamic>.from(
              langNamespaces[RegexUtils.defaultNamespace]!)
          : Map<String, dynamic>.from(langNamespaces.values.first);

      for (final regionEntry in regionData.entries) {
        final composedTag = '$langTag-${regionEntry.key}';
        if (existingTags.contains(composedTag)) continue;

        final merged = _deepMerge(langTranslations, regionEntry.value);
        translationMap.addTranslations(
          locale: I18nLocale.fromString(composedTag),
          translations: merged,
        );
      }
    }
  }

  /// Deep-merges [overlay] on top of [base]. Nested maps are merged
  /// recursively; scalar values from [overlay] replace those in [base].
  static Map<String, dynamic> _deepMerge(
      Map<String, dynamic> base, Map<String, dynamic> overlay) {
    final result = Map<String, dynamic>.from(base);
    for (final entry in overlay.entries) {
      if (entry.value is Map<String, dynamic> &&
          result[entry.key] is Map<String, dynamic>) {
        result[entry.key] = _deepMerge(
            result[entry.key] as Map<String, dynamic>,
            entry.value as Map<String, dynamic>);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}

extension on Map<String, Map<String, dynamic>> {
  Map<String, dynamic> digest() {
    if (length > 1 && containsKey(RegexUtils.defaultNamespace)) {
      return {
        ...this[RegexUtils.defaultNamespace]!,
        ...{
          for (final entry in entries)
            if (entry.key != RegexUtils.defaultNamespace)
              entry.key: entry.value,
        },
      };
    }

    return this;
  }
}