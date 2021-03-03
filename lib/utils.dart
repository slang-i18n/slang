class Utils {
  static RegExp argumentsRegex = RegExp(r'([^\\]|^)\$\{?(\w+)\}?');

  /// Finds the parts of the locale. It must start with an underscore.
  static RegExp localeRegex =
      RegExp(r'^((\w+)_)?([a-z]{2})([-_]([a-zA-Z]{2}))?$');

  /// Returns the locale with the following syntax:
  /// - dash as separator
  static String normalize(String locale) {
    return locale.replaceAll('_', '-');
  }
}
