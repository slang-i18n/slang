/// Similar to the [Locale] class of Flutter
/// But without any Flutter dependencies
class AppLocaleId {
  final String languageCode;
  final String? scriptCode;
  final String? countryCode;

  static const AppLocaleId UNDEFINED_LANGUAGE = AppLocaleId(
    languageCode: 'und',
  );

  const AppLocaleId({
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
  });

  String get languageTag => [languageCode, scriptCode, countryCode]
      .where((element) => element != null)
      .join('-');

  @override
  String toString() =>
      'AppLocaleId{languageCode: $languageCode, scriptCode: $scriptCode, countryCode: $countryCode}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLocaleId &&
          runtimeType == other.runtimeType &&
          languageCode == other.languageCode &&
          scriptCode == other.scriptCode &&
          countryCode == other.countryCode;

  @override
  int get hashCode =>
      languageCode.hashCode ^ scriptCode.hashCode ^ countryCode.hashCode;
}

// This locale is *shared* among all packages of an app.
AppLocaleId get currLocaleId => _currLocaleId;
AppLocaleId _currLocaleId = AppLocaleId.UNDEFINED_LANGUAGE;

class BaseLocaleSettings {
  final AppLocaleId baseLocale;
  final List<AppLocaleId> localeValues;

  BaseLocaleSettings({required this.baseLocale, required this.localeValues});

  /// Sets locale, *but* do not change potential TranslationProvider's state
  /// Useful when you are in a pure Dart environment (without Flutter)
  AppLocaleId setLocaleExceptProvider(AppLocaleId locale) {
    _currLocaleId = locale;
    return currentLocaleId;
  }

  /// Gets current locale.
  AppLocaleId get currentLocaleId => _currLocaleId;

  /// Gets supported locales in string format.
  List<String> get supportedLocalesRaw {
    return localeValues.map((locale) => locale.languageTag).toList();
  }
}

/// Provides utility functions without any side effects.
class AppLocaleUtils {
  final List<AppLocaleId> localeValues;

  AppLocaleUtils(this.localeValues);

  /// Returns the enum type of the raw locale.
  /// Fallbacks to base locale.
  AppLocaleId? parse(String rawLocale) {
    return selectLocale(rawLocale);
  }

  static final _localeRegex =
      RegExp(r'^([a-z]{2,8})?([_-]([A-Za-z]{4}))?([_-]?([A-Z]{2}|[0-9]{3}))?$');

  AppLocaleId? selectLocale(String localeRaw) {
    final match = _localeRegex.firstMatch(localeRaw);
    AppLocaleId? selected;
    if (match != null) {
      final language = match.group(1);
      final country = match.group(5);

      // match exactly
      selected = localeValues.cast<AppLocaleId?>().firstWhere(
          (supported) =>
              supported?.languageTag == localeRaw.replaceAll('_', '-'),
          orElse: () => null);

      if (selected == null && language != null) {
        // match language
        selected = localeValues.cast<AppLocaleId?>().firstWhere(
            (supported) => supported?.languageTag.startsWith(language) == true,
            orElse: () => null);
      }

      if (selected == null && country != null) {
        // match country
        selected = localeValues.cast<AppLocaleId?>().firstWhere(
            (supported) => supported?.languageTag.contains(country) == true,
            orElse: () => null);
      }
    }
    return selected;
  }
}
