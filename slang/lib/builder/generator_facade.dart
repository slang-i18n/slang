import 'package:slang/builder/builder/build_model_config_builder.dart';
import 'package:slang/builder/builder/generate_config_builder.dart';
import 'package:slang/builder/builder/translation_model_builder.dart';
import 'package:slang/builder/generator/generator.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/build_result.dart';
import 'package:slang/builder/model/i18n_data.dart';
import 'package:slang/builder/model/interface.dart';
import 'package:slang/builder/model/translation_map.dart';

class GeneratorFacade {
  /// Common step used by custom runner and builder to get the .g.dart content
  static BuildResult generate({
    required RawConfig rawConfig,
    required String baseName,
    required TranslationMap translationMap,
  }) {
    // combine namespaces and build the internal model
    final List<I18nData> translationList =
        translationMap.getEntries().map((localeEntry) {
      final locale = localeEntry.key;
      final namespaces = localeEntry.value;
      return TranslationModelBuilder.build(
        buildConfig: rawConfig.toBuildModelConfig(),
        locale: locale,
        map: rawConfig.namespaces ? namespaces : namespaces.values.first,
      );
    }).toList();

    // prepare model for generation

    // sort: base locale, then all other locales
    translationList.sort(I18nData.generationComparator);

    // combine all interfaces of all locales
    // if one interface appears on more than one locale, then the interface of
    // the base locale will have precedence
    final interfaceMap = <String, Interface>{};
    translationList.forEach((locale) {
      locale.interfaces.forEach((interface) {
        if (!interfaceMap.containsKey(interface.name)) {
          interfaceMap[interface.name] = interface;
        }
      });
    });

    // build config
    final config = GenerateConfigBuilder.build(
      baseName: baseName,
      buildConfig: rawConfig,
      interfaces: interfaceMap.values.toList(),
    );

    // generate .g.dart file
    return Generator.generate(
      config: config,
      translations: translationList,
    );
  }
}
