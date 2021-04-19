class Utils {
  static RegExp argumentsRegex = RegExp(r'([^\\]|^)\$\{?(\w+)\}?');

  /// Finds the parts of the locale. It must start with an underscore.
  /// groups for zh-Hant-TW:
  /// 2 = strings
  /// 3 = zh (language)
  /// 5 = Hant (script)
  /// 7 = TW (country)
  static RegExp fileWithLocaleRegex = RegExp(
      r'^(([a-zA-Z0-9]+)_)?([A-Za-z]{2,4})([_-]([A-Za-z]{4}))?([_-]([A-Za-z]{2}|[0-9]{3}))?$');

  static RegExp baseFileRegex = RegExp(r'^([a-zA-Z0-9]+)?$');

  /// Returns the locale with the following syntax:
  /// - dash as separator
  static String normalize(String locale) {
    return locale.replaceAll('_', '-');
  }
}
