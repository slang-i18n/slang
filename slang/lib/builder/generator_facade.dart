import 'package:slang/builder/builder/generate_config_builder.dart';
import 'package:slang/builder/generator/generator.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/build_result.dart';
import 'package:slang/builder/model/interface.dart';
import 'package:slang/builder/model/translation_map.dart';

class GeneratorFacade {
  /// Common step used by custom runner and builder to get the .g.dart content
  static BuildResult generate({
    required RawConfig rawConfig,
    required String baseName,
    required TranslationMap translationMap,
  }) {
    // build translation model
    final translationModelList = translationMap.toI18nModel(rawConfig);

    // prepare model for generation

    // combine all interfaces of all locales
    // if one interface appears on more than one locale, then the interface of
    // the base locale will have precedence
    final interfaceMap = <String, Interface>{};
    translationModelList.forEach((locale) {
      locale.interfaces.forEach((interface) {
        if (!interfaceMap.containsKey(interface.name)) {
          interfaceMap[interface.name] = interface;
        }
      });
    });

    // generate config
    final config = GenerateConfigBuilder.build(
      baseName: baseName,
      config: rawConfig,
      interfaces: interfaceMap.values.toList(),
    );

    // generate .g.dart file
    return Generator.generate(
      config: config,
      translations: translationModelList,
    );
  }
}
