import 'package:slang/builder/builder/build_model_config_builder.dart';
import 'package:slang/builder/builder/translation_model_builder.dart';
import 'package:slang/builder/model/i18n_data.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/raw_config.dart';

/// Contains ALL translations of ALL locales
/// Represented as pure maps without modifications
///
/// locale -> (namespace -> translation map)
class TranslationMap {
  final _internalMap = <I18nLocale, Map<String, Map<String, dynamic>>>{};

  /// Read access
  Map<String, Map<String, dynamic>>? operator [](I18nLocale key) {
    return _internalMap[key];
  }

  /// Add a namespace and its translations
  /// Namespace may be ignored if this feature is not used
  void addTranslations({
    required I18nLocale locale,
    String namespace = 'not relevant',
    required Map<String, dynamic> translations,
  }) {
    if (!_internalMap.containsKey(locale)) {
      // ensure that the locale exists
      _internalMap[locale] = {};
    }

    _internalMap[locale]![namespace] = translations;
  }

  /// Return all locales specified in this map
  List<I18nLocale> getLocales() {
    return _internalMap.keys.toList();
  }

  /// Combine all namespaces and build the internal model
  /// The locales are sorted (base locale first)
  ///
  /// After this method call, information about the namespace is lost.
  /// It will be just a normal parent.
  List<I18nData> toI18nModel(RawConfig rawConfig) {
    final buildConfig = rawConfig.toBuildModelConfig();
    return _internalMap.entries.map((localeEntry) {
      final locale = localeEntry.key;
      final namespaces = localeEntry.value;
      return TranslationModelBuilder.build(
        buildConfig: buildConfig,
        map: rawConfig.namespaces ? namespaces : namespaces.values.first,
        localeDebug: locale.languageTag,
      ).toI18nData(base: rawConfig.baseLocale == locale, locale: locale);
    }).toList()
      ..sort(I18nData.generationComparator);
  }
}
