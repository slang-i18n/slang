import 'package:slang/api/pluralization.dart';
import 'package:slang/builder/model/node.dart';

/// Root translation class of ONE locale
/// Entry point for every translation
abstract class BaseTranslations<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> {
  /// Metadata of this root translation class
  TranslationMetadata<E, T> get $meta;
}

/// Metadata instance hold by the root translation class.
class TranslationMetadata<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> {
  final E locale;
  dynamic Function(String path) get getTranslation => _flatMapFunction!;
  final Map<String, Node> overrides;
  final PluralResolver? cardinalResolver;
  final PluralResolver? ordinalResolver;

  dynamic Function(String path)? _flatMapFunction;

  TranslationMetadata({
    required this.locale,
    required this.overrides,
    required this.cardinalResolver,
    required this.ordinalResolver,
  });

  void setFlatMapFunction(dynamic Function(String key) func) {
    _flatMapFunction = func;
  }
}

/// Returns a new translation instance
typedef TranslationBuilder<E extends BaseAppLocale<E, T>,
        T extends BaseTranslations<E, T>>
    = T Function({
  Map<String, Node>? overrides,
  PluralResolver? cardinalResolver,
  PluralResolver? ordinalResolver,
});

/// Similar to flutter locale
/// but available without any flutter dependencies
abstract class BaseAppLocale<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> {
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
  TranslationBuilder<E, T> get build;

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

class BasicAppLocale
    extends BaseAppLocale<BasicAppLocale, _DefaultTranslations> {
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
  TranslationBuilder<BasicAppLocale, _DefaultTranslations> get build {
    return ({overrides, cardinalResolver, ordinalResolver}) =>
        _DefaultTranslations(BasicAppLocale(
          languageCode: languageCode,
          scriptCode: scriptCode,
          countryCode: countryCode,
        ));
  }
}

class _DefaultTranslations
    extends BaseTranslations<BasicAppLocale, _DefaultTranslations> {
  _DefaultTranslations(BasicAppLocale locale)
      : $meta = TranslationMetadata(
          locale: locale,
          overrides: {},
          cardinalResolver: null,
          ordinalResolver: null,
        );

  final TranslationMetadata<BasicAppLocale, _DefaultTranslations> $meta;
}
