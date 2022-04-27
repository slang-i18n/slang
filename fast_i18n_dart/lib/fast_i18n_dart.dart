class BaseAppLocale {
  final String languageCode;
  final String? scriptCode;
  final String? countryCode;

  const BaseAppLocale({
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
  });
}

class FastI18nDartInternalUtil {
  static final _localeRegex = RegExp(r'^([a-z]{2,8})?([_-]([A-Za-z]{4}))?([_-]?([A-Z]{2}|[0-9]{3}))?$');

  static T? selectLocale<T extends BaseAppLocale>(List<T> values, String localeRaw) {
    final match = _localeRegex.firstMatch(localeRaw);
    T? selected;
    if (match != null) {
      final language = match.group(1);
      final country = match.group(5);

      // match exactly
      selected = values
          .cast<T?>()
          .firstWhere((supported) => supported?.languageTag == localeRaw.replaceAll('_', '-'), orElse: () => null);

      if (selected == null && language != null) {
        // match language
        selected = values
            .cast<T?>()
            .firstWhere((supported) => supported?.languageTag.startsWith(language) == true, orElse: () => null);
      }

      if (selected == null && country != null) {
        // match country
        selected = values
            .cast<T?>()
            .firstWhere((supported) => supported?.languageTag.contains(country) == true, orElse: () => null);
      }
    }
    return selected;
  }
}
