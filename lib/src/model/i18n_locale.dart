import 'package:fast_i18n/src/utils.dart';

/// own Locale type to decouple from dart:ui package
class I18nLocale {
  final String language;
  final String? script;
  final String? country;

  I18nLocale({required this.language, this.script, this.country});

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

  static I18nLocale fromString(String localeRaw) {
    final match = Utils.fileWithLocaleRegex.firstMatch(localeRaw);
    if (match != null) {
      final language = match.group(3);
      final script = match.group(5);
      final country = match.group(7);
      return I18nLocale(
          language: language ?? '', script: script, country: country);
    }
    return I18nLocale(language: localeRaw);
  }
}
