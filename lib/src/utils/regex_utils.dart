class RegexUtils {
  /// matches $argument or ${argument}
  static RegExp argumentsDartRegex = RegExp(r'([^\\]|^)\$\{?(\w+)\}?');

  /// matches {argument}
  /// 1 = pre character (to check \)
  /// 2 = actual argument
  /// 3 = post character is word, therefore ${...}
  static RegExp argumentsBracesRegex = RegExp(r'(.|^)\{(\w+)\}(\w)?');

  /// matches {{argument}}
  /// similar group indices like [argumentsBracesRegex]
  static RegExp argumentsDoubleBracesRegex = RegExp(r'(.|^)\{\{(\w+)\}\}(\w)?');

  /// matches @:translation.key
  static RegExp linkedRegex = RegExp(r'@:(\w[\w|.]*\w|\w)');

  /// matches $hello, $ but not \$
  static RegExp dollarRegex = RegExp(r'([^\\]|^)\$');

  /// matches only $ but not \$
  static RegExp dollarOnlyRegex = RegExp(r'([^\\]|^)\$( |$)');

  /// locale regex
  static const LOCALE_REGEX_RAW =
      r'([a-z]{2,8})?([_-]([A-Za-z]{4}))?([_-]?([A-Z]{2}|[0-9]{3}))?';

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
