class Utils {
  static RegExp argumentsRegex = RegExp(r'([^\\]|^)\$\{?(\w+)\}?');

  /// finds the parts of the locale
  /// must start with an underscore
  static RegExp localeRegex = RegExp(r'^((\w+)_)?([a-z]{2})([-_]([a-zA-Z]{2}))?$');

  /// returns the locale with the following syntax:
  /// - all lowercase
  /// - dash as separator
  static String normalize(String locale) {
    return locale.toLowerCase().replaceAll('_', '-');
  }
}
