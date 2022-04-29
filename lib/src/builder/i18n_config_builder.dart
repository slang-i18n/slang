import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/interface.dart';
import 'package:fast_i18n/src/model/pluralization.dart';
import 'package:fast_i18n/src/model/pluralization_resolvers.dart';

class I18nConfigBuilder {
  static I18nConfig build({
    required String baseName,
    required BuildConfig buildConfig,
    required List<I18nData> translationList,
    required List<Interface> interfaces,
  }) {
    Map<String, RuleSet> renderedCardinalResolvers = {};
    Map<String, RuleSet> renderedOrdinalResolvers = {};
    Set<String> unsupportedPluralLanguages = {};
    for (final translationData in translationList) {
      final language = translationData.locale.language;
      final pluralizationResolver = PLURALIZATION_RESOLVERS[language];
      if (pluralizationResolver == null) {
        if (translationData.hasCardinal || translationData.hasOrdinal) {
          unsupportedPluralLanguages.add(language);
        }
        continue;
      }

      if (translationData.hasCardinal) {
        renderedCardinalResolvers[language] = pluralizationResolver.cardinal;
      }

      if (translationData.hasOrdinal) {
        renderedOrdinalResolvers[language] = pluralizationResolver.ordinal;
      }
    }

    return I18nConfig(
      baseName: baseName,
      baseLocale: buildConfig.baseLocale,
      fallbackStrategy: buildConfig.fallbackStrategy,
      outputFormat: buildConfig.outputFormat,
      renderLocaleHandling: buildConfig.renderLocaleHandling,
      dartOnly: buildConfig.dartOnly,
      renderedCardinalResolvers: renderedCardinalResolvers,
      renderedOrdinalResolvers: renderedOrdinalResolvers,
      unsupportedPluralLanguages: unsupportedPluralLanguages,
      translateVariable: buildConfig.translateVar,
      enumName: buildConfig.enumName,
      translationClassVisibility: buildConfig.translationClassVisibility,
      renderFlatMap: buildConfig.renderFlatMap,
      renderTimestamp: buildConfig.renderTimestamp,
      contexts: buildConfig.contexts,
      interface: interfaces,
    );
  }
}
