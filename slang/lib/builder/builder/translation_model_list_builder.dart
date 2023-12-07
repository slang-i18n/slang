import 'package:slang/builder/builder/build_model_config_builder.dart';
import 'package:slang/builder/builder/translation_model_builder.dart';
import 'package:slang/builder/model/i18n_data.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/translation_map.dart';

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

    return translationMap.getInternalMap().entries.map((localeEntry) {
      final locale = localeEntry.key;
      final namespaces = localeEntry.value;
      final result = TranslationModelBuilder.build(
        buildConfig: buildConfig,
        map: rawConfig.namespaces ? namespaces : namespaces.values.first,
        localeDebug: locale.languageTag,
      );

      return I18nData(
        base: rawConfig.baseLocale == locale,
        locale: locale,
        root: result.root,
        contexts: result.contexts,
        interfaces: result.interfaces,
      );
    }).toList()
      ..sort(I18nData.generationComparator);
  }
}
