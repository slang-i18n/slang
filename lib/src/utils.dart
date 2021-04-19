class Utils {
  static RegExp argumentsRegex = RegExp(r'([^\\]|^)\$\{?(\w+)\}?');

  static const LOCALE_REGEX_RAW =
      r'([A-Za-z]{2,4})([_-]([A-Za-z]{4}))?([_-]([A-Za-z]{2}|[0-9]{3}))?';

  /// Finds the parts of the locale. It must start with an underscore.
  /// groups for zh-Hant-TW:
  /// 2 = strings
  /// 3 = zh (language)
  /// 5 = Hant (script)
  /// 7 = TW (country)
  static RegExp fileWithLocaleRegex =
      RegExp('^(([a-zA-Z0-9]+)_)?$LOCALE_REGEX_RAW\$');

  static RegExp localeRegex = RegExp('^$LOCALE_REGEX_RAW\$');

  static RegExp baseFileRegex = RegExp(r'^([a-zA-Z0-9]+)?$');
}
