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
    // match exactly
    final exactMatch = locales.firstWhereOrNull((supported) =>
        supported.languageCode == languageCode &&
        supported.scriptCode == scriptCode &&
        supported.countryCode == countryCode);

    if (exactMatch != null) {
      return exactMatch;
    }

    final candidates = locales.where((supported) {
      return supported.languageCode == languageCode;
    });

    if (candidates.length == 1) {
      // match language code
      return candidates.first;
    }

    if (countryCode == null) {
      // no country code given
      return candidates.firstOrNull ?? baseLocale;
    }

    if (candidates.isEmpty) {
      // match country code
      return locales.firstWhereOrNull((supported) {
            return supported.countryCode == countryCode;
          }) ??
          baseLocale;
    } else {
      // there are multiple locales with same language code
      // e.g. zh-Hans, zh-Hant-HK, zh-Hant-TW
      return candidates.firstWhereOrNull((candidate) {
            return candidate.countryCode == countryCode;
          }) ??
          baseLocale;
    }
  }

  /// Gets supported locales in string format.
  List<String> get supportedLocalesRaw {
    return locales.map((locale) => locale.languageTag).toList();
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
      isFlatMap: false,
      map: BaseDecoder.getDecoderOfFileType(fileType).decode(content),
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
    );
  }

  /// Creates a translation instance using the given [map].
  T buildWithOverridesFromMap({
    required E locale,
    required bool isFlatMap,
    required Map map,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) {
    if (buildConfig == null) {
      throw 'BuildConfig is null. Please generate the translations with <translation_overrides: true>';
    }

    final Map<String, dynamic> digestedMap;
    if (isFlatMap) {
      digestedMap = {};
      for (final entry in map.entries) {
        MapUtils.addItemToMap(
          map: digestedMap,
          destinationPath: entry.key,
          item:
              entry.value is Map ? MapUtils.deepCast(entry.value) : entry.value,
        );
      }
    } else {
      digestedMap = MapUtils.deepCast(map);
    }

    final buildResult = TranslationModelBuilder.build(
      buildConfig: buildConfig!,
      map: digestedMap,
      handleLinks: false,
      localeDebug: locale.languageTag,
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
  /// Internal: Manages all translation instances
  /// May be modified when setting a custom plural resolver
  final Map<E, T> translationMap;

  /// Internal: Reference to utils instance
  final BaseAppLocaleUtils<E, T> utils;

  /// If true, then [TranslationProvider] will trigger [setLocale] on
  /// device locale change (e.g. due to user interaction in device settings).
  bool listenToDeviceLocale = false;

  BaseLocaleSettings({
    required this.utils,
  }) : this.translationMap = _buildMap(utils.locales);

  /// Updates the provider state and therefore triggers a rebuild
  /// on all widgets listening to this provider.
  ///
  /// This is a flutter feature and this method will be overridden
  /// by slang_flutter.
  void updateProviderState(BaseAppLocale locale) {}
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
  /// It fires every time LocaleSettings.setLocale, LocaleSettings.setLocaleRaw,
  /// or LocaleSettings.useDeviceLocale is called.
  ///
  /// To additionally listen to device locale changes, either call
  /// (1) LocaleSettings.useDeviceLocale
  /// (2) or set [listenToDeviceLocale] to `true`.
  /// Both will fire [setLocale] when device locale changes.
  /// You need to wrap your app with [TranslationProvider].
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
    return utils.supportedLocalesRaw;
  }

  /// Sets locale.
  /// Returns the locale which has been set.
  ///
  /// Locale gets changed automatically if [listenToDeviceLocale] is true
  /// and [TranslationProvider] is used. If null, then the last state is used.
  /// By default, calling this method disables the listener.
  E setLocale(E locale, {bool? listenToDeviceLocale = false}) {
    GlobalLocaleState.instance.setLocale(locale);
    updateProviderState(locale);
    if (listenToDeviceLocale != null) {
      this.listenToDeviceLocale = listenToDeviceLocale;
    }
    return locale;
  }

  /// Sets locale using string tag (e.g. en_US, de-DE, fr)
  /// Fallbacks to base locale.
  /// Returns the locale which has been set.
  ///
  /// Locale gets changed automatically if [listenToDeviceLocale] is true
  /// and [TranslationProvider] is used. If null, then the last state is used.
  /// By default, calling this method disables the listener.
  E setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) {
    final E locale = utils.parse(rawLocale);
    return setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
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
      targetLocales =
          utils.locales.where((l) => l.languageCode == language).toList();
    } else {
      throw 'Either language or locale must be specified';
    }

    // update translation instances
    for (final curr in targetLocales) {
      final overrides = translationMap[curr]!.$meta.overrides;
      translationMap[curr] = curr.build(
        // keep old overrides
        overrides: overrides.isNotEmpty ? overrides : null,
        cardinalResolver: cardinalResolver,
        ordinalResolver: ordinalResolver,
      );
    }
  }

  /// Overrides existing translations of [locale] with new ones from [content].
  /// The [content] should be formatted and structured exactly the same way
  /// as the original files.
  ///
  /// Adding new parameters will not cause an error
  /// but users will see an unparsed ${parameter}.
  ///
  /// It is allowed to override only selected keys.
  /// Calling this method multiple times will delete the old overrides.
  ///
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
      updateProviderState(locale);
    }
  }

  /// Overrides existing translations of [locale] with new ones from the [map].
  ///
  /// If [isFlatMap] is true, then the keys of the map are interpreted as paths.
  /// E.g. {'myPath.toKey': 'Updated Text'}
  /// If [isFlatMap] is false, then the structure is like a parsed json.
  ///
  /// Checkout [overrideTranslations] for more documentation.
  ///
  /// Please do a try-catch to prevent app crashes!
  void overrideTranslationsFromMap({
    required E locale,
    required bool isFlatMap,
    required Map map,
  }) {
    final currentMetadata = translationMap[locale]!.$meta;
    translationMap[locale] = utils.buildWithOverridesFromMap(
      locale: locale,
      isFlatMap: isFlatMap,
      map: map,
      cardinalResolver: currentMetadata.cardinalResolver,
      ordinalResolver: currentMetadata.ordinalResolver,
    );
    if (locale == currentLocale) {
      updateProviderState(locale);
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
