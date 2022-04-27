class BaseAppLocale {
  final String languageCode;
  final String? scriptCode;
  final String? countryCode;

  const BaseAppLocale({
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
  });

  String get languageTag => [languageCode, scriptCode, countryCode].where((element) => element != null).join('-');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseAppLocale &&
          runtimeType == other.runtimeType &&
          languageCode == other.languageCode &&
          scriptCode == other.scriptCode &&
          countryCode == other.countryCode;

  @override
  int get hashCode => languageCode.hashCode ^ scriptCode.hashCode ^ countryCode.hashCode;
}

class BaseLocaleSettings<T extends BaseAppLocale> {
  final T baseLocale;
  final List<T> localeValues;

  T _currLocale;

  BaseLocaleSettings({required this.baseLocale, required this.localeValues}) : _currLocale = baseLocale;

  /// Uses locale of the device, fallbacks to base locale.
  /// Returns the locale which has been set.
  T useDeviceLocale() {
    final locale = AppLocaleUtils.findDeviceLocale();
    return setLocale(locale);
  }

  /// Sets locale
  /// Returns the locale which has been set.
  T setLocale(T locale) {
    _currLocale = locale;

    if (WidgetsBinding.instance != null) {
      // force rebuild if TranslationProvider is used
      _translationProviderKey.currentState?.setLocale(_currLocale);
    }

    return _currLocale;
  }

  /// Sets locale using string tag (e.g. en_US, de-DE, fr)
  /// Fallbacks to base locale.
  /// Returns the locale which has been set.
  T setLocaleRaw(String rawLocale) {
    final locale = AppLocaleUtils.parse(rawLocale);
    return setLocale(locale);
  }

  /// Gets current locale.
  T get currentLocale => _currLocale;

  /// Gets supported locales in string format.
  List<String> get supportedLocalesRaw {
    return localeValues.map((locale) => locale.languageTag).toList();
  }

  /// Gets supported locales (as Locale objects) with base locale sorted first.
  List<Locale> get supportedLocales {
    return localeValues.map((locale) => locale.flutterLocale).toList();
  }
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

/// Provides utility functions without any side effects.
class AppLocaleUtils {
  AppLocaleUtils._(); // no constructor

  /// Returns the locale of the device as the enum type.
  /// Fallbacks to base locale.
  static AppLocale findDeviceLocale() {
    final String? deviceLocale = WidgetsBinding.instance?.window.locale.toLanguageTag();
    if (deviceLocale != null) {
      final typedLocale = FastI18nDartInternalUtil.selectLocale(deviceLocale);
      if (typedLocale != null) {
        return typedLocale;
      }
    }
    return _baseLocale;
  }

  /// Returns the enum type of the raw locale.
  /// Fallbacks to base locale.
  static AppLocale parse(String rawLocale) {
    return FastI18nDartInternalUtil.selectLocale(rawLocale) ?? _baseLocale;
  }
}

