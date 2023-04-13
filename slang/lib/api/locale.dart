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

  /// The secret.
  /// Used to decrypt obfuscated translation strings.
  final int s;

  dynamic Function(String path)? _flatMapFunction;

  TranslationMetadata({
    required this.locale,
    required this.overrides,
    required this.cardinalResolver,
    required this.ordinalResolver,
    this.s = 0,
  });

  void setFlatMapFunction(dynamic Function(String key) func) {
    _flatMapFunction = func;
  }

  /// Decrypts the given [chars] by XOR-ing them with the secret [s].
  ///
  /// Keep in mind that this is not a secure encryption method.
  /// It only makes static analysis of the compiled binary harder.
  ///
  /// You should enable Flutter obfuscation for additional security.
  String d(List<int> chars) {
    for (int i = 0; i < chars.length; i++) {
      chars[i] = chars[i] ^ s;
    }
    return String.fromCharCodes(chars);
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
      FakeAppLocale(languageCode: 'und');

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

class FakeAppLocale extends BaseAppLocale<FakeAppLocale, FakeTranslations> {
  @override
  final String languageCode;

  @override
  final String? scriptCode;

  @override
  final String? countryCode;

  FakeAppLocale({
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
  });

  @override
  TranslationBuilder<FakeAppLocale, FakeTranslations> get build {
    return ({overrides, cardinalResolver, ordinalResolver}) => FakeTranslations(
          FakeAppLocale(
            languageCode: languageCode,
            scriptCode: scriptCode,
            countryCode: countryCode,
          ),
          overrides: overrides,
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
        );
  }
}

class FakeTranslations
    extends BaseTranslations<FakeAppLocale, FakeTranslations> {
  FakeTranslations(
    FakeAppLocale locale, {
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    int? s,
  })  : $meta = TranslationMetadata(
          locale: locale,
          overrides: overrides ?? {},
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
          s: s ?? 0,
        ),
        providedNullOverrides = overrides == null;

  @override
  final TranslationMetadata<FakeAppLocale, FakeTranslations> $meta;

  /// Internal: This is only for unit test purposes
  final bool providedNullOverrides;
}
