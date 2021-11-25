import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/string_extensions.dart';
import 'package:fast_i18n/src/utils/regex_utils.dart';

/// own Locale type to decouple from dart:ui package
class I18nLocale {
  static const String UNDEFINED_LANGUAGE = 'und';

  final String? language;
  final String? script;
  final String? country;
  late String languageTag = _toLanguageTag();
  late String enumConstant = _toEnumConstant();

  I18nLocale({this.language, this.script, this.country});

  String _toLanguageTag() {
    return [language, script, country]
        .where((element) => element != null)
        .join('-');
  }

  String _toEnumConstant() {
    final result = _toLanguageTag().toLowerCase().toCase(CaseStyle.camel);
    if (result == 'in') {
      return 'india'; // hardcode to india because 'in' is a keyword
    } else {
      return result;
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
    final match = RegexUtils.localeRegex.firstMatch(localeRaw);
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
