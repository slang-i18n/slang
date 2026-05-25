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
  bool get isWildcard => languageIsWildcard || countryIsWildcard;
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

  /// Expands wildcard locales into specific locales
  /// based on the provided lists of languages and countries.
  List<I18nLocale> expandLocales({
    required Set<String> anyLanguages,
    required Set<String> anyCountries,
  }) {
    final List<String> languages;
    if (languageIsWildcard) {
      languages = language == 'any'
          ? anyLanguages.toList()
          : language.split(',').map((s) => s.trim()).toList();
    } else {
      languages = [language];
    }

    final List<String?> countries;
    if (countryIsWildcard) {
      countries = country == 'any'
          ? anyCountries.toList()
          : country!.split(',').map((s) => s.trim()).toList();
    } else {
      countries = [country];
    }

    final result = <I18nLocale>[];
    for (final languageRaw in languages) {
      final parsedLanguage = I18nLocale.tryFromString(languageRaw);
      for (final c in countries) {
        result.add(I18nLocale(
          language: parsedLanguage?.language ?? languageRaw,
          script: parsedLanguage?.script ?? script,
          country: parsedLanguage?.country ?? c,
          generatedFromWildcard: true,
        ));
      }
    }

    return result;
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

extension I18nLocaleListExtension on List<I18nLocale> {
  Set<String> getDistinctLanguageCodes() {
    final anyLanguages = <String>{};

    for (final locale in this) {
      if (locale.languageIsWildcard) {
        if (locale.language != 'any') {
          // Language (e.g. [de,fr-FR]) may contain country,
          // we need to parse it to get the language part only
          final languages = locale.language
              .split(',')
              .map((s) => I18nLocale.tryFromString(s)?.language)
              .nonNulls;
          anyLanguages.addAll(languages);
        }
      } else {
        anyLanguages.add(locale.language);
      }
    }

    return anyLanguages;
  }

  Set<String> getDistinctCountryCodes() {
    final anyCountries = <String>{};

    for (final locale in this) {
      if (locale.languageIsWildcard && locale.language != 'any') {
        // Language (e.g. [de,fr-FR]) may contain country,
        // we need to parse it to get the country part only
        final languages = locale.language
            .split(',')
            .map((s) => I18nLocale.tryFromString(s)?.country)
            .nonNulls;
        anyCountries.addAll(languages);
      }

      if (locale.countryIsWildcard) {
        if (locale.country != 'any') {
          final countries = locale.country!.split(',').map((s) => s.trim());
          anyCountries.addAll(countries);
        }
      } else if (locale.country != null) {
        anyCountries.add(locale.country!);
      }
    }

    return anyCountries;
  }
}
