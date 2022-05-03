import 'package:fast_i18n/builder/generator/generate_header.dart';
import 'package:fast_i18n/builder/generator/generate_translations.dart';
import 'package:fast_i18n/builder/model/build_result.dart';
import 'package:fast_i18n/builder/model/i18n_config.dart';
import 'package:fast_i18n/builder/model/i18n_data.dart';

class Generator {
  /// main generate function
  /// returns a string representing the content of the .g.dart file
  static BuildResult generate({
    required I18nConfig config,
    required List<I18nData> translations,
  }) {
    final header = generateHeader(config, translations);
    final list = Map.fromEntries(translations
        .map((t) => MapEntry(t.locale, generateTranslations(config, t))));
    final String? flatMap;
    if (config.renderFlatMap) {
      flatMap = generateTranslationMap(config, translations);
    } else {
      flatMap = null;
    }

    return BuildResult(
      header: header,
      translations: list,
      flatMap: flatMap,
    );
  }
}
