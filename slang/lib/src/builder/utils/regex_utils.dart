class RegexUtils {
  /// matches $argument or ${argument} but not \$argument
  /// 1 = argument of $argument
  /// 2 = argument of ${argument}
  static final RegExp argumentsDartRegex =
      RegExp(r'(?<!\\)\$(?:([\w]+)|\{(.+?)\})');

  /// matches @:translation.key or @:{translation.key}, but not \@:translation.key
  /// 1 = argument of @:translation.key
  /// 2 = argument of @:{translation.key}
  static final RegExp linkedRegex = RegExp(
    r'(?<!\\)@:(?:(\w[\w|.]*\w|\w)|\{(\w[\w|.]*\w|\w)\})',
  );

  /// matches $hello, $ but not \$
  static final RegExp dollarRegex = RegExp(r'([^\\]|^)\$');

  /// matches only $ but not \$
  static final RegExp dollarOnlyRegex = RegExp(r'([^\\]|^)\$( |$)');

  /// locale regex
  static const localeRegexRaw =
      r'([a-z]{2,3})(?:[_-]([A-Za-z]{4}))?(?:[_-]([A-Z]{2}|[0-9]{3}))?';

  static const defaultNamespace = '_default';

  /// Finds the parts of the locale. It must start with an underscore.
  /// groups for strings-zh-Hant-TW:
  /// 1 = strings
  /// 2 = zh (language, non-nullable)
  /// 3 = Hant (script)
  /// 4 = TW (country)
  static final RegExp fileWithLocaleRegex =
      RegExp('^(?:([a-zA-Z0-9]+|$defaultNamespace)[_-])?$localeRegexRaw\$');

  /// matches locale part only
  /// 1 - language (non-nullable)
  /// 2 - script
  /// 3 - country
  static final RegExp localeRegex = RegExp('^$localeRegexRaw\$');

  /// matches any string without special characters
  static final RegExp baseFileRegex = RegExp(r'^([a-zA-Z0-9]+)?$');

  /// Matches an attribute entry
  /// String? content(name)
  /// 1 - String
  /// 3 - ?
  /// 4 - content
  /// 5 - (name,age)
  static final RegExp attributeRegex =
      RegExp(r'^((\w|\<|\>|,)+)(\?)? (\w+)(\(.+\))?$');

  /// Matches the generic of the list
  /// `List<MyGeneric>`
  /// 1 - MyGeneric
  static final RegExp genericRegex = RegExp(r'^List<((?:\w| |<|>)+)>$');

  /// Matches the modifier part in a key if it exists
  /// greet(plural, param=gender)
  /// 1 - greet
  /// 2 - plural, param=gender
  static final RegExp modifierRegex = RegExp(r'^([\w-]+)\((.+)\)$');

  /// Matches a format type expression with optional parameters
  ///
  /// NumberFormat.currency(cool: 334)
  /// 1 - NumberFormat.currency
  /// 2 - cool: 334
  ///
  /// currency
  /// 1 - currency
  static final RegExp formatTypeRegex = RegExp(r'^([\w.]+)(?:\((.+)\))?$');

  static final RegExp spaceRegex = RegExp(r'\s+');

  static final RegExp linkPathRegex = RegExp(r'^_root\.((?:[.\w])+)\(?');

  /// Matches plurals or selects of format (variable,type,content)
  /// {sex, select, male{His birthday} female{Her birthday} other{Their birthday}}
  /// 1 - sex
  /// 2 -  select
  /// 3 -  male{His birthday} female{Her birthday} other{Their birthday}
  static final RegExp arbComplexNode =
      RegExp(r'^{((?: |\w)+),((?: |\w)+),(.+)}$');

  /// Matches the parts of the content
  /// male{His birthday} female{Her birthday} other{Their birthday}
  /// 1st match - male{His birthday}
  /// 2nd match - female{Her birthday}
  /// 3rd match - other{Their birthday}
  ///
  /// 1 - male
  /// 2 - His birthday
  static final RegExp arbComplexNodeContent =
      RegExp(r'((?:=|\w)+) *{((?:[^}{]+|{[^}]+})+)}');

  /// Matches any missing translations file
  /// _missing_translations.json, _missing_translations_de-DE.json
  /// _unused_translations.json, _unused_translations_de-DE.json
  ///
  /// 1 - missing_translations or unused_translations
  /// 2 - de-DE
  /// 3 - json
  static final RegExp analysisFileRegex = RegExp(
      r'^_(missing_translations|unused_translations)(?:_(.*))?\.(json|yaml|csv)$');

  /// Matches if the string starts with a number.
  /// Example: 1hello, 2world
  static final RegExp startsWithNumber = RegExp(r'^\d');
}
