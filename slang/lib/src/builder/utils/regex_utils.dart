class RegexUtils {
  /// matches $argument or ${argument} but not \$argument
  /// 1 = argument of $argument
  /// 2 = argument of ${argument}
  static RegExp argumentsDartRegex = RegExp(r'(?<!\\)\$(?:([\w]+)|\{(.+?)\})');

  /// matches @:translation.key
  static RegExp linkedRegex = RegExp(r'@:(\w[\w|.]*\w|\w)');

  /// matches $hello, $ but not \$
  static RegExp dollarRegex = RegExp(r'([^\\]|^)\$');

  /// matches only $ but not \$
  static RegExp dollarOnlyRegex = RegExp(r'([^\\]|^)\$( |$)');

  /// matches `param(arg)`
  static RegExp paramWithArg = RegExp(r'^(\w+)(\((.+)\))?$');

  /// locale regex
  static const LOCALE_REGEX_RAW =
      r'([a-z]{2,3})(?:[_-]([A-Za-z]{4}))?(?:[_-]([A-Z]{2}|[0-9]{3}))?';

  /// Finds the parts of the locale. It must start with an underscore.
  /// groups for strings-zh-Hant-TW:
  /// 1 = strings
  /// 2 = zh (language, non-nullable)
  /// 3 = Hant (script)
  /// 4 = TW (country)
  static RegExp fileWithLocaleRegex =
      RegExp('^(?:([a-zA-Z0-9]+)[_-])?$LOCALE_REGEX_RAW\$');

  /// matches locale part only
  /// 1 - language (non-nullable)
  /// 2 - script
  /// 3 - country
  static RegExp localeRegex = RegExp('^$LOCALE_REGEX_RAW\$');

  /// matches any string without special characters
  static RegExp baseFileRegex = RegExp(r'^([a-zA-Z0-9]+)?$');

  /// Matches an attribute entry
  /// String? content(name)
  /// 1 - String
  /// 3 - ?
  /// 4 - content
  /// 5 - (name,age)
  static RegExp attributeRegex =
      RegExp(r'^((\w|\<|\>|,)+)(\?)? (\w+)(\(.+\))?$');

  /// Matches the generic of the list
  /// List<MyGeneric>
  /// 1 - MyGeneric
  static RegExp genericRegex = RegExp(r'^List<((?:\w| |<|>)+)>$');

  /// Matches the modifier part in a key if it exists
  /// greet(plural, param=gender)
  /// 1 - greet
  /// 2 - plural, param=gender
  static RegExp modifierRegex = RegExp(r'^(\w+)\((.+)\)$');

  static RegExp spaceRegex = RegExp(r'\s+');

  static RegExp linkPathRegex = RegExp(r'^_root\.((?:[.\w])+)\(?');

  /// Matches plurals or selects of format (variable,type,content)
  /// {sex, select, male{His birthday} female{Her birthday} other{Their birthday}}
  /// 1 - sex
  /// 2 -  select
  /// 3 -  male{His birthday} female{Her birthday} other{Their birthday}
  static RegExp arbComplexNode = RegExp(r'^{((?: |\w)+),((?: |\w)+),(.+)}$');

  /// Matches the parts of the content
  /// male{His birthday} female{Her birthday} other{Their birthday}
  /// 1st match - male{His birthday}
  /// 2nd match - female{Her birthday}
  /// 3rd match - other{Their birthday}
  ///
  /// 1 - male
  /// 2 - His birthday
  static RegExp arbComplexNodeContent =
      RegExp(r'((?:=|\w)+){((?:[^}{]+|{[^}]+})+)}');

  /// Matches any missing translations file
  /// _missing_translations.json, _missing_translations_de-DE.json
  /// _unused_translations.json, _unused_translations_de-DE.json
  ///
  /// 1 - missing_translations or unused_translations
  /// 2 - de-DE
  /// 3 - json
  static RegExp analysisFileRegex = RegExp(
      r'^_(missing_translations|unused_translations)(?:_(.*))?\.(json|yaml|csv)$');
}
