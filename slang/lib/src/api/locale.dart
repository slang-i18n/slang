import 'package:slang/src/api/formatter.dart';
import 'package:slang/src/api/pluralization.dart';
import 'package:slang/src/builder/model/node.dart';

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
  final Map<String, ValueFormatter> types;

  /// The secret.
  /// Used to decrypt obfuscated translation strings.
  final int s;

  dynamic Function(String path)? _flatMapFunction;

  TranslationMetadata({
    required this.locale,
    required this.overrides,
    required this.cardinalResolver,
    required this.ordinalResolver,
    this.types = const {},
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

/// Similar to flutter locale
/// but available without any flutter dependencies.
/// Subclasses will be enums.
abstract mixin class BaseAppLocale<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> {
  String get languageCode;

  String? get scriptCode;

  String? get countryCode;

  /// Gets a new translation instance.
  /// [LocaleSettings] has no effect here.
  /// Suitable for dependency injection and unit tests.
  ///
  /// Usage:
  /// final t = await AppLocale.en.build(); // build
  /// String a = t.my.path; // access
  Future<T> build({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  });

  /// Similar to [build] but synchronous.
  /// This might throw an error on Web if
  /// the library is not loaded yet (Deferred Loading).
  T buildSync({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  });

  static final BaseAppLocale undefinedLocale =
      FakeAppLocale(languageCode: 'und');

  /// Concatenates language, script and country code with dashes.
  /// Resembles [Locale.toLanguageTag] of dart:ui.
  String get languageTag => [languageCode, scriptCode, countryCode]
      .where((element) => element != null)
      .join('-');

  /// For whatever reason, the intl package uses underscores instead of dashes
  /// that contradicts https://www.unicode.org/reports/tr35/
  /// that is used by the Locale class in dart:ui.
  String get underscoreTag => [languageCode, scriptCode, countryCode]
      .where((element) => element != null)
      .join('_');

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

  final Map<String, ValueFormatter>? types;

  FakeAppLocale({
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
    this.types,
  });

  @override
  Future<FakeTranslations> build({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) async =>
      buildSync(
        overrides: overrides,
        cardinalResolver: cardinalResolver,
        ordinalResolver: ordinalResolver,
      );

  @override
  FakeTranslations buildSync({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) {
    return FakeTranslations(
      FakeAppLocale(
        languageCode: languageCode,
        scriptCode: scriptCode,
        countryCode: countryCode,
      ),
      overrides: overrides,
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
      types: types,
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
    Map<String, ValueFormatter>? types,
    int? s,
  })  : $meta = TranslationMetadata(
          locale: locale,
          overrides: overrides ?? {},
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
          types: types ?? {},
          s: s ?? 0,
        ),
        providedNullOverrides = overrides == null;

  @override
  final TranslationMetadata<FakeAppLocale, FakeTranslations> $meta;

  /// Internal: This is only for unit test purposes
  final bool providedNullOverrides;
}
