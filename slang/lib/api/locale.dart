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

  static final BaseAppLocale undefinedLocale =
      BasicAppLocale(languageCode: 'und');

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

class BasicAppLocale extends BaseAppLocale<_DefaultTranslations> {
  @override
  final String languageCode;

  @override
  final String? scriptCode;

  @override
  final String? countryCode;

  BasicAppLocale({
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
  });

  @override
  TranslationBuilder<_DefaultTranslations> get build {
    return ({cardinalResolver, ordinalResolver}) => _DefaultTranslations();
  }
}

class _DefaultTranslations extends BaseTranslations {}
