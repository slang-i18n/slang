import 'package:slang/api/pluralization.dart';

/// Root translation class
/// Entry point for every translation
abstract class BaseTranslations {}

/// Returns a new translation instance
typedef TranslationBuilder<T extends BaseTranslations> = T Function({
  PluralResolver? cardinalResolver,
  PluralResolver? ordinalResolver,
});

/// Similar to flutter locale
/// but available without any flutter dependencies
abstract class BaseAppLocale<T extends BaseTranslations> {
  String get languageCode;
  String? get scriptCode;
  String? get countryCode;

  /// Gets a new translation instance.
  /// [LocaleSettings] has no effect here.
  /// Suitable for dependency injection and unit tests.
  ///
  /// Usage:
  /// final t = AppLocale.en.build(); // build
  /// String a = t.my.path; // access
  TranslationBuilder<T> get build;

  static final BaseAppLocale UNDEFINED_LANGUAGE = _DefaultAppLocale();

  String get languageTag => [languageCode, scriptCode, countryCode]
      .where((element) => element != null)
      .join('-');

  bool sameLocale(BaseAppLocale other) {
    return languageCode == other.languageCode &&
        scriptCode == other.scriptCode &&
        countryCode == other.countryCode;
  }

  @override
  String toString() =>
      'BaseAppLocale{languageCode: $languageCode, scriptCode: $scriptCode, countryCode: $countryCode}';
}

// default classes to avoid null values

class _DefaultAppLocale extends BaseAppLocale<_DefaultTranslations> {
  @override
  String get languageCode => 'und';

  @override
  String? get scriptCode => null;

  @override
  String? get countryCode => null;

  @override
  TranslationBuilder<_DefaultTranslations> get build {
    return ({cardinalResolver, ordinalResolver}) {
      return _DefaultTranslations();
    };
  }
}

class _DefaultTranslations extends BaseTranslations {}
