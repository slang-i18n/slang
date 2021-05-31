import 'package:fast_i18n/src/utils.dart';

/// own Locale type to decouple from dart:ui package
class I18nLocale {
  final String language;
  final String script;
  final String country;

  I18nLocale({this.language, this.script, this.country});

  String toLanguageTag() {
    if (script != null && country != null) {
      // 3 parts
      return '$language-$script-$country';
    } else {
      final secondPart = script ?? country;
      if (secondPart != null) {
        // 2 parts
        return '$language-$secondPart';
      } else {
        // 1 part (language only)
        return language;
      }
    }
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

  static I18nLocale fromString(String localeRaw) {
    final match = Utils.localeRegex.firstMatch(localeRaw);
    if (match != null) {
      final language = match.group(1);
      final script = match.group(3);
      final country = match.group(5);
      return I18nLocale(
          language: language ?? '', script: script, country: country);
    }
    return I18nLocale(language: localeRaw);
  }
}
