import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';

/// own Locale type to decouple from dart:ui package
class I18nLocale {
  static const String undefinedLanguage = 'und';

  final String language;
  final bool languageIsWildcard;
  final String? script;
  final String? country;
  final bool countryIsWildcard;
  final bool generatedFromWildcard;
  late String languageTag = _toLanguageTag();
  late String underscoreTag = languageTag.replaceAll('-', '_');
  late String enumConstant = _toEnumConstant();

  I18nLocale({
    required this.language,
    this.languageIsWildcard = false,
    this.script,
    this.country,
    this.countryIsWildcard = false,
    this.generatedFromWildcard = false,
  });

  String _toLanguageTag() {
    return [language, script, country]
        .where((element) => element != null)
        .join('-');
  }

  String _toEnumConstant() {
    final result = _toLanguageTag().toCaseOfLocale(CaseStyle.camel);

    // Take care of reserved words
    return switch (result) {
      'is' => 'icelandic',
      'in' => 'india',
      _ => result,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is I18nLocale &&
        language == other.language &&
        script == other.script &&
        country == other.country;
  }

  @override
  int get hashCode {
    return language.hashCode * script.hashCode * country.hashCode;
  }

  @override
  String toString() => 'I18nLocale($languageTag)';

  static I18nLocale fromString(String localeRaw) {
    return tryFromString(localeRaw) ?? I18nLocale(language: localeRaw);
  }

  static I18nLocale? tryFromString(String localeRaw) {
    final match = RegexUtils.localeRegex.firstMatch(localeRaw);
    if (match == null) {
      return null;
    }

    final language = match.group(1) ?? match.group(2)!;
    final script = match.group(3);
    final country = match.group(4) ?? match.group(5);
    return I18nLocale(
      language: language,
      languageIsWildcard: match.group(2) != null,
      script: script,
      country: country,
      countryIsWildcard: match.group(5) != null,
    );
  }
}
