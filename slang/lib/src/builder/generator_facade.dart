import 'package:slang/builder/builder/generate_config_builder.dart';
import 'package:slang/builder/builder/translation_model_list_builder.dart';
import 'package:slang/builder/model/build_result.dart';
import 'package:slang/builder/model/context_type.dart';
import 'package:slang/builder/model/interface.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/translation_map.dart';
import 'package:slang/src/builder/generator/generator.dart';

class GeneratorFacade {
  /// Common step used by custom runner and builder to get the .g.dart content
  static BuildResult generate({
    required RawConfig rawConfig,
    required String baseName,
    required TranslationMap translationMap,
    required String inputDirectoryHint,
  }) {
    // build translation model
    final translationModelList = TranslationModelListBuilder.build(
      rawConfig,
      translationMap,
    );

    // prepare model for generation

    // combine all contexts of all locales
    // if one context appears on more than one locale, then the context of
    // the base locale will have precedence
    final contextMap = <String, PopulatedContextType>{};
    for (final locale in translationModelList) {
      for (final context in locale.contexts) {
        if (!contextMap.containsKey(context.enumName)) {
          contextMap[context.enumName] = context;
        }
      }
    }

    // combine all interfaces of all locales
    // if one interface appears on more than one locale, then the interface of
    // the base locale will have precedence
    final interfaceMap = <String, Interface>{};
    for (final locale in translationModelList) {
      for (final interface in locale.interfaces) {
        if (!interfaceMap.containsKey(interface.name)) {
          interfaceMap[interface.name] = interface;
        }
      }
    }

    // generate config
    final config = GenerateConfigBuilder.build(
      baseName: baseName,
      config: rawConfig,
      inputDirectoryHint: inputDirectoryHint,
      contexts: contextMap.values.toList(),
      interfaces: interfaceMap.values.toList(),
    );

    // generate .g.dart file
    return Generator.generate(
      config: config,
      translations: translationModelList,
    );
  }
}
