import 'package:collection/collection.dart';
import 'package:slang/api/locale.dart';
import 'package:slang/api/pluralization.dart';
import 'package:slang/api/state.dart';
import 'package:slang/builder/builder/translation_model_builder.dart';
import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/model/build_model_config.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/utils/map_utils.dart';
import 'package:slang/builder/utils/node_utils.dart';
import 'package:slang/builder/utils/regex_utils.dart';

/// Provides utility functions without any side effects.
abstract class BaseAppLocaleUtils<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> {
  /// Internal: The base locale
  final E baseLocale;

  /// Internal: All locales, unordered
  final List<E> locales;

  /// Internal: Used for translation overrides
  final BuildModelConfig? buildConfig;

  BaseAppLocaleUtils({
    required this.baseLocale,
    required this.locales,
    this.buildConfig,
  });
}

// We use extension methods here to have a workaround for static members of the same name
extension AppLocaleUtilsExt<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> on BaseAppLocaleUtils<E, T> {
  /// Parses the raw locale to get the enum.
  /// Fallbacks to base locale.
  E parse(String rawLocale) {
    final match = RegexUtils.localeRegex.firstMatch(rawLocale);
    if (match == null) {
      return baseLocale;
    }

    return parseLocaleParts(
      languageCode: match.group(1)!,
      scriptCode: match.group(2),
      countryCode: match.group(3),
    );
  }

  /// Gets the [E] type of [locale].
  ///
  /// [locale] may have a locale which is unsupported by [E].
  /// In this case, the base locale will be returned.
  E parseAppLocale(BaseAppLocale locale) {
    if (locale is E) {
      return locale; // take it directly
    }

    return parseLocaleParts(
      languageCode: locale.languageCode,
      scriptCode: locale.scriptCode,
      countryCode: locale.countryCode,
    );
  }

  /// Finds the locale type [E] which fits the locale parts the best.
  /// Fallbacks to base locale.
  E parseLocaleParts({
    required String languageCode,
    String? scriptCode,
    String? countryCode,
  }) {
    E? selected;

    // match exactly
    selected = locales.firstWhereOrNull((supported) =>
        supported.languageCode == languageCode &&
        supported.scriptCode == scriptCode &&
        supported.countryCode == countryCode);

    if (selected == null) {
      // match language
      selected = locales.firstWhereOrNull((supported) {
        return supported.languageCode == languageCode;
      });
    }

    if (selected == null && countryCode != null) {
      // match country
      selected = locales.firstWhereOrNull((supported) {
        return supported.countryCode == countryCode;
      });
    }

    return selected ?? baseLocale;
  }

  /// Creates a translation instance with overrides stored in [content].
  T buildWithOverrides({
    required E locale,
    required FileType fileType,
    required String content,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) {
    return buildWithOverridesFromMap(
      locale: locale,
      map: BaseDecoder.getDecoderOfFileType(fileType).decode(content),
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
    );
  }

  /// Creates a translation instance using the given [map].
  T buildWithOverridesFromMap({
    required E locale,
    required Map map,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) {
    if (buildConfig == null) {
      throw 'BuildConfig is null. Please generate the translations with <translation_overrides: true>';
    }

    final buildResult = TranslationModelBuilder.build(
      buildConfig: buildConfig!,
      localeDebug: locale.languageTag,
      map: MapUtils.deepCast(map),
    );

    return locale.build(
      overrides: buildResult.root.toFlatMap(),
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
    );
  }
}

abstract class BaseLocaleSettings<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> {
  /// Locale enums sorted alphabetically and base locale first
  final List<E> locales;

  /// The base locale
  final E baseLocale;

  /// Internal: Manages all translation instances
  /// May be modified when setting a custom plural resolver
  final Map<E, T> translationMap;

  /// Internal: Reference to utils instance
  final BaseAppLocaleUtils<E, T> utils;

  BaseLocaleSettings({
    required this.locales,
    required this.baseLocale,
    required this.utils,
  }) : this.translationMap = _buildMap(locales);

  /// Updates the provider state and therefore triggers a rebuild
  /// on all widgets listening to this provider.
  ///
  /// This is a flutter feature and this method will be overridden
  /// by slang_flutter.
  void updateProviderState(E locale, T translations) {}
}

// We use extension methods here to have a workaround for static members of the same name
extension LocaleSettingsExt<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> on BaseLocaleSettings<E, T> {
  /// Gets current locale.
  E get currentLocale {
    final locale = GlobalLocaleState.instance.getLocale();
    return utils.parseAppLocale(locale);
  }

  /// Gets the broadcast stream to keep track of every locale change.
  ///
  /// Usage:
  /// LocaleSettings.getLocaleStream().listen((locale) {
  ///   print('new locale: $locale');
  /// });
  Stream<E> getLocaleStream() {
    return GlobalLocaleState.instance.getStream().map((locale) {
      return utils.parseAppLocale(locale);
    });
  }

  /// Gets current translations
  T get currentTranslations {
    return translationMap[currentLocale]!;
  }

  /// Gets supported locales in string format.
  List<String> get supportedLocalesRaw {
    return locales.map((locale) => locale.languageTag).toList();
  }

  /// Sets locale, *but* do not change potential TranslationProvider's state
  /// Useful when you are in a pure Dart environment (without Flutter)
  /// This will be overwritten when using with flutter.
  E setLocale(E locale) {
    GlobalLocaleState.instance.setLocale(locale);
    updateProviderState(locale, translationMap[locale]!);
    return locale;
  }

  /// Sets locale using string tag (e.g. en_US, de-DE, fr)
  /// Fallbacks to base locale.
  /// Returns the locale which has been set.
  E setLocaleRaw(String rawLocale) {
    final E locale = utils.parse(rawLocale);
    return setLocale(locale);
  }

  /// Sets plural resolvers.
  /// See https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html
  /// See https://github.com/Tienisto/slang/blob/master/slang/lib/api/plural_resolver_map.dart
  /// Either specify [language], or [locale]. [locale] has precedence.
  void setPluralResolver({
    String? language,
    E? locale,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) {
    final List<E> targetLocales;
    if (locale != null) {
      // take only this locale
      targetLocales = [locale];
    } else if (language != null) {
      // map to language
      targetLocales = locales.where((l) => l.languageCode == language).toList();
    } else {
      throw 'Either language or locale must be specified';
    }

    // update translation instances
    for (final curr in targetLocales) {
      translationMap[curr] = curr.build(
        overrides: translationMap[curr]!.$meta.overrides, // keep old overrides
        cardinalResolver: cardinalResolver,
        ordinalResolver: ordinalResolver,
      );
    }
  }

  /// Overrides existing translations of [locale] with new ones from [content].
  /// Please do a try-catch to prevent app crashes!
  void overrideTranslations({
    required E locale,
    required FileType fileType,
    required String content,
  }) {
    final currentMetadata = translationMap[locale]!.$meta;
    translationMap[locale] = utils.buildWithOverrides(
      locale: locale,
      content: content,
      fileType: fileType,
      cardinalResolver: currentMetadata.cardinalResolver,
      ordinalResolver: currentMetadata.ordinalResolver,
    );
    if (locale == currentLocale) {
      updateProviderState(locale, translationMap[locale]!);
    }
  }

  /// Overrides existing translations of [locale] with new ones from the [map].
  /// Please do a try-catch to prevent app crashes!
  void overrideTranslationsFromMap({required E locale, required Map map}) {
    final currentMetadata = translationMap[locale]!.$meta;
    translationMap[locale] = utils.buildWithOverridesFromMap(
      locale: locale,
      map: map,
      cardinalResolver: currentMetadata.cardinalResolver,
      ordinalResolver: currentMetadata.ordinalResolver,
    );
    if (locale == currentLocale) {
      updateProviderState(locale, translationMap[locale]!);
    }
  }
}

Map<E, T>
    _buildMap<E extends BaseAppLocale<E, T>, T extends BaseTranslations<E, T>>(
        List<E> locales) {
  return <E, T>{
    for (final key in locales) key: key.build(),
  };
}
