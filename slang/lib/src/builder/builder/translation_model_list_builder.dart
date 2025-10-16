import 'package:slang/src/builder/builder/build_model_config_builder.dart';
import 'package:slang/src/builder/builder/translation_model_builder.dart';
import 'package:slang/src/builder/model/i18n_data.dart';
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
