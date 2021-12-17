import 'package:fast_i18n/src/generator/generate_header.dart';
import 'package:fast_i18n/src/generator/generate_translations.dart';
import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';

class Generator {
  /// main generate function
  /// returns a string representing the content of the .g.dart file
  static String generate({
    required I18nConfig config,
    required List<I18nData> translations,
  }) {
    StringBuffer buffer = StringBuffer();

    generateHeader(buffer, config, translations, DateTime.now().toUtc());

    buffer.writeln();
    buffer.writeln('// translations');

    for (I18nData localeData in translations) {
      generateTranslations(buffer, config, localeData);
    }

    if (config.renderFlatMap) {
      generateTranslationMap(buffer, config, translations);
    }

    return buffer.toString();
  }
}
