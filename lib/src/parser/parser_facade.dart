import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/parser/json_parser.dart';
import 'package:fast_i18n/src/parser/yaml_parser.dart';

class ParserFacade {
  /// Takes a string representing a file content and parses it according
  /// to the fileType specified in [BuildConfig].
  ///
  /// It essentially delegates the task to the specific parser.
  static I18nData parseTranslations({
    required BuildConfig config,
    required I18nLocale locale,
    required String content,
  }) {
    switch (config.fileType) {
      case FileType.json:
        return JsonParser.parseTranslations(config, locale, content);
      case FileType.yaml:
        return YamlParser.parseTranslations(config, locale, content);
    }
  }
}
