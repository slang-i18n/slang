import 'package:fast_i18n/src/builder/i18n_config_builder.dart';
import 'package:fast_i18n/src/builder/translation_model_builder.dart';
import 'package:fast_i18n/src/generator/generator.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/build_result.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/interface.dart';
import 'package:fast_i18n/src/model/namespace_translation_map.dart';

class GeneratorFacade {
  /// Common step used by custom runner and builder to get the .g.dart content
  static BuildResult generate({
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
      return TranslationModelBuilder.build(
        buildConfig: buildConfig,
        locale: locale,
        map: buildConfig.namespaces ? namespaces : namespaces.values.first,
      );
    }).toList();

    // prepare model for generation

    // sort: base locale, then all other locales
    translationList.sort(I18nData.generationComparator);

    // combine all interfaces of all locales
    // if one interface appears on more than one locale, then the interface of
    // the base locale will have precedence
    Map<String, Interface> interfaceMap = {};
    translationList.forEach((locale) {
      locale.interfaces.forEach((interface) {
        if (!interfaceMap.containsKey(interface)) {
          interfaceMap[interface.name] = interface;
        }
      });
    });

    // build config
    final config = I18nConfigBuilder.build(
      baseName: baseName,
      buildConfig: buildConfig,
      translationList: translationList,
      interfaces: interfaceMap.values.toList(),
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
