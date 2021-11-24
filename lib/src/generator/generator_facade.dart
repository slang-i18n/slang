import 'package:fast_i18n/src/builder/i18n_config_builder.dart';
import 'package:fast_i18n/src/builder/node_builder.dart';
import 'package:fast_i18n/src/generator/generate.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/namespace_translation_map.dart';

class GeneratorFacade {
  /// Common step used by custom runner and builder to get the .g.dart content
  static String generate({
    required BuildConfig buildConfig,
    required String baseName,
    required NamespaceTranslationMap translationMap,
    bool showPluralHint = false,
  }) {
    // combine namespaces
    final List<I18nData> translationList =
        translationMap.getEntries().map((localeEntry) {
      final locale = localeEntry.key;
      final namespaces = localeEntry.value;
      final buildResult = NodeBuilder.fromMap(
        config: buildConfig,
        locale: locale,
        map: buildConfig.namespaces ? namespaces : namespaces.values.first,
      );
      return I18nData(
        base: buildConfig.baseLocale == locale,
        locale: locale,
        root: buildResult.root,
        hasCardinal: buildResult.hasCardinal,
        hasOrdinal: buildResult.hasOrdinal,
      );
    }).toList();

    // prepare model for generation

    // sort: base locale, then all other locales
    translationList.sort(I18nData.generationComparator);

    // build config
    final config = I18nConfigBuilder.build(
      baseName: baseName,
      buildConfig: buildConfig,
      translationList: translationList,
    );

    if (showPluralHint && config.hasPlurals()) {
      // show pluralization hints if pluralization is configured
      print('');
      print('Pluralization:');
      print(
          ' -> rendered resolvers: ${config.getRenderedPluralResolvers().toList()}');
      print(
          ' -> you must implement these resolvers: ${config.unsupportedPluralLanguages.toList()}');
    }

    // generate .g.dart file
    return Generator.generate(
      config: config,
      translations: translationList,
    );
  }
}
