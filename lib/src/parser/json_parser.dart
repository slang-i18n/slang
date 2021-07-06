import 'dart:convert';

import 'package:fast_i18n/src/builder/node_builder.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';

class JsonParser {
  /// parses a json of one locale
  /// returns an I18nData object
  static I18nData parseTranslations(
      BuildConfig config, I18nLocale locale, String content) {
    Map<String, dynamic> map = json.decode(content);
    return I18nData(
      base: config.baseLocale == locale,
      locale: locale,
      root: NodeBuilder.fromMap(config, map),
    );
  }
}
