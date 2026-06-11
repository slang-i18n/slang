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

    final queue = translationMap.getInternalMap().entries.toList();
    queue.sort((a, b) =>
        I18nLocale.generationComparator(a.key, b.key, rawConfig.baseLocale));

    final existingResults = <I18nLocale, I18nData>{};
    return queue.map((localeEntry) {
      final locale = localeEntry.key;
      final namespaces = localeEntry.value;
      final base = locale == rawConfig.baseLocale;

      final hasChildLocales =
          locale.hasChildLocales(translationMap.getLocales());

      final result = TranslationModelBuilder.build(
        buildConfig: buildConfig,
        map: rawConfig.namespaces
            ? namespaces.expand()
            : ExpandedNamespaceMap(namespaces.values.first),
        baseData: existingResults[rawConfig.baseLocale],
        locale: locale,
      );

      final fallbackLocale = TranslationModelBuilder.getFallbackLocale(
        fallbackStrategy: buildConfig.fallbackStrategy,
        locale: locale,
        baseLocale: rawConfig.baseLocale,
        locales: translationMap.getLocales(),
      );

      final data = I18nData(
        base: base,
        locale: locale,
        fallbackLocale: fallbackLocale,
        fallbackData: existingResults[fallbackLocale.locale],
        classVisibility: base
            ? CodeVisibility.public
            : rawConfig.translationClassVisibility == CodeVisibility.public ||
                    hasChildLocales
                ? CodeVisibility.public
                : CodeVisibility.private,
        constructorVisibility: (base &&
                    (buildConfig.fallbackStrategy ==
                            FallbackStrategy.baseLocale ||
                        buildConfig.fallbackStrategy ==
                            FallbackStrategy.baseLocaleEmptyString)) ||
                hasChildLocales
            ? CodeVisibility.public
            : CodeVisibility.private,
        root: result.root,
        contexts: result.contexts,
        interfaces: result.interfaces,
        types: result.types,
      );

      existingResults[locale] = data;

      return data;
    }).toList();
  }
}
