class Utils {
  /// check if special character exists
  static RegExp specialRegex = RegExp(r'[^a-zA-Z0-9]');

  /// finds the parts of the locale
  /// must start with an underscore
  static RegExp localeRegex = RegExp(r'_([a-z]{2})([-_]([a-zA-Z]{2}))?$');

  /// returns the locale with the following syntax:
  /// - all lowercase
  /// - dash as separator
  static String normalize(String locale) {
    return locale.toLowerCase().replaceAll('_', '-');
  }
}
