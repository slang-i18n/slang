import 'package:slang/overrides.dart';
import 'package:slang/src/builder/builder/build_model_config_builder.dart';
import 'package:slang/src/builder/builder/translation_model_builder.dart';
import 'package:slang/src/builder/model/i18n_data.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/translation_map.dart';

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

    final baseEntry = translationMap.getInternalMap().entries.firstWhere(
          (entry) => entry.key == rawConfig.baseLocale,
          orElse: () => throw Exception('Base locale not found'),
        );

    // Create the base data first.
    final namespaces = baseEntry.value;
    final baseResult = TranslationModelBuilder.build(
      buildConfig: buildConfig,
      map: rawConfig.namespaces ? namespaces.expand() : namespaces.values.first,
      locale: baseEntry.key,
    );

    return translationMap.getInternalMap().entries.map((localeEntry) {
      final locale = localeEntry.key;
      final namespaces = localeEntry.value;
      final base = locale == rawConfig.baseLocale;

      final hasChildLocales =
          _hasChildLocales(locale, translationMap.getLocales());

      if (base) {
        // Use the already computed base data
        return I18nData(
          base: true,
          locale: locale,
          fallbackLocale: FallbackLocale(
            locale: rawConfig.baseLocale,
            fallback: false,
          ),
          classVisibility: rawConfig.translationClassVisibility ==
                      CodeVisibility.public ||
                  buildConfig.fallbackStrategy == FallbackStrategy.baseLocale ||
                  buildConfig.fallbackStrategy ==
                      FallbackStrategy.baseLocaleEmptyString ||
                  hasChildLocales
              ? CodeVisibility.public
              : CodeVisibility.private,
          constructorVisibility:
              buildConfig.fallbackStrategy == FallbackStrategy.baseLocale ||
                      buildConfig.fallbackStrategy ==
                          FallbackStrategy.baseLocaleEmptyString ||
                      hasChildLocales
                  ? CodeVisibility.public
                  : CodeVisibility.private,
          root: baseResult.root,
          contexts: baseResult.contexts,
          interfaces: baseResult.interfaces,
          types: baseResult.types,
        );
      } else {
        final defaultFallback = switch (buildConfig.fallbackStrategy) {
          FallbackStrategy.none => false,
          FallbackStrategy.baseLocale ||
          FallbackStrategy.baseLocaleEmptyString =>
            true,
        };
        final FallbackLocale? fallbackLocale;
        if (locale.country == null && locale.script == null) {
          // e.g. "de" only inherits the base locale like "en"
          fallbackLocale = FallbackLocale(
            locale: rawConfig.baseLocale,
            fallback: defaultFallback,
          );
        } else {
          // e.g. "de-CH" inherits "de" if it exists, otherwise the base locale
          // If "de" exists, it will **always** inherit it.
          if (_hasParentLocale(locale, translationMap.getLocales())) {
            fallbackLocale = FallbackLocale(
              locale: I18nLocale(language: locale.language),
              fallback: true,
            );
          } else {
            fallbackLocale = FallbackLocale(
              locale: rawConfig.baseLocale,
              fallback: defaultFallback,
            );
          }
        }

        final result = TranslationModelBuilder.build(
          buildConfig: buildConfig,
          map: rawConfig.namespaces
              ? namespaces.expand()
              : namespaces.values.first,
          baseData: baseResult,
          locale: locale,
        );

        return I18nData(
          base: false,
          locale: locale,
          fallbackLocale: fallbackLocale,
          classVisibility:
              rawConfig.translationClassVisibility == CodeVisibility.public ||
                      hasChildLocales
                  ? CodeVisibility.public
                  : CodeVisibility.private,
          constructorVisibility:
              hasChildLocales ? CodeVisibility.public : CodeVisibility.private,
          root: result.root,
          contexts: result.contexts,
          interfaces: result.interfaces,
          types: result.types,
        );
      }
    }).toList()
      ..sort(I18nData.generationComparator);
  }
}

bool _hasParentLocale(I18nLocale locale, List<I18nLocale> allLocales) {
  return allLocales.any((l) =>
      l != locale &&
      l.language == locale.language &&
      l.script == null &&
      l.country == null);
}

bool _hasChildLocales(I18nLocale locale, List<I18nLocale> allLocales) {
  return allLocales.any((l) =>
      l != locale &&
      l.language == locale.language &&
      (l.script != null || l.country != null));
}
