class Utils {
  /// matches $argument or ${argument}
  static RegExp argumentsDartRegex = RegExp(r'([^\\]|^)\$\{?(\w+)\}?');

  /// matches {argument}
  static RegExp argumentsBracesRegex = RegExp(r'([^\\]|^)\{(\w+)\}');

  /// matches {{argument}}
  static RegExp argumentsDoubleBracesRegex = RegExp(r'([^\\]|^)\{\{(\w+)\}\}');

  /// locale regex
  static const LOCALE_REGEX_RAW =
      r'([A-Za-z]{2,4})([_-]([A-Za-z]{4}))?([_-]([A-Za-z]{2}|[0-9]{3}))?';

  /// Finds the parts of the locale. It must start with an underscore.
  /// groups for strings_zh-Hant-TW:
  /// 2 = strings
  /// 3 = zh (language)
  /// 5 = Hant (script)
  /// 7 = TW (country)
  static RegExp fileWithLocaleRegex =
      RegExp('^(([a-zA-Z0-9]+)_)?$LOCALE_REGEX_RAW\$');

  /// matches locale part only
  /// 1 - language
  /// 3 - script
  /// 5 - country
  static RegExp localeRegex = RegExp('^$LOCALE_REGEX_RAW\$');

  /// matches any string without special characters
  static RegExp baseFileRegex = RegExp(r'^([a-zA-Z0-9]+)?$');
}
