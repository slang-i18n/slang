import 'package:collection/collection.dart';
import 'package:slang/src/api/locale.dart';
import 'package:slang/src/api/pluralization.dart';
import 'package:slang/src/api/state.dart';
import 'package:slang/src/builder/builder/translation_model_builder.dart';
import 'package:slang/src/builder/decoder/base_decoder.dart';
import 'package:slang/src/builder/model/build_model_config.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/builder/utils/node_utils.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';

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

    if (candidates.isEmpty) {
      // no matching language, try match country code only
      return locales.firstWhereOrNull((supported) {
            return supported.countryCode == countryCode;
          }) ??
          baseLocale;
    }

    // There is at least a locale with matching language code
    final fallback = candidates.first;

    if (countryCode == null) {
      // no country code given
      return fallback;
    }

    // there are multiple locales with same language code
    // e.g. zh-Hans, zh-Hant-HK, zh-Hant-TW
    return candidates.firstWhereOrNull((candidate) {
          return candidate.countryCode == countryCode;
        }) ??
        fallback;
  }

  /// Gets supported locales in string format.
  List<String> get supportedLocalesRaw {
    return locales.map((locale) => locale.languageTag).toList();
  }

  /// Creates a translation instance with overrides stored in [content].
  Future<T> buildWithOverrides({
    required E locale,
    required FileType fileType,
    required String content,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) async {
    return await buildWithOverridesFromMap(
      locale: locale,
      isFlatMap: false,
      map: BaseDecoder.decodeWithFileType(fileType, content),
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
    );
  }

  /// Sync version of [buildWithOverrides].
  T buildWithOverridesSync({
    required E locale,
    required FileType fileType,
    required String content,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) {
    return buildWithOverridesFromMapSync(
      locale: locale,
      isFlatMap: false,
      map: BaseDecoder.decodeWithFileType(fileType, content),
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
    );
  }

  /// Creates a translation instance using the given [map].
  Future<T> buildWithOverridesFromMap({
    required E locale,
    required bool isFlatMap,
    required Map map,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) async {
    final buildResult = _buildWithOverridesFromMap(
      locale: locale,
      isFlatMap: isFlatMap,
      map: map,
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
    );
    return await locale.build(
      overrides: buildResult.root.toFlatMap(),
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
    );
  }

  /// Sync version of [buildWithOverridesFromMap].
  T buildWithOverridesFromMapSync({
    required E locale,
    required bool isFlatMap,
    required Map map,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) {
    final buildResult = _buildWithOverridesFromMap(
      locale: locale,
      isFlatMap: isFlatMap,
      map: map,
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
    );
    return locale.buildSync(
      overrides: buildResult.root.toFlatMap(),
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
    );
  }

  BuildModelResult _buildWithOverridesFromMap({
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

    return TranslationModelBuilder.build(
      buildConfig: buildConfig!,
      map: digestedMap,
      handleLinks: false,
      shouldEscapeText: false,
      localeDebug: locale.languageTag,
    );
  }
}

abstract class BaseLocaleSettings<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> {
  /// Internal: Manages all translation instances.
  /// The base locale is always included.
  /// Additional locales are added when calling [loadLocale].
  /// May be modified when setting a custom plural resolver.
  final Map<E, T> translationMap;

  /// Internal:
  /// Keeps track of loading translations to prevent multiple requests.
  /// This lock is sufficient because Dart's async loop is single-threaded.
  final Set<E> translationsLoading = {};

  /// Internal: Reference to utils instance
  final BaseAppLocaleUtils<E, T> utils;

  /// If true, then [TranslationProvider] will trigger [setLocale] on
  /// device locale change (e.g. due to user interaction in device settings).
  bool listenToDeviceLocale = false;

  BaseLocaleSettings({
    required this.utils,
    required bool lazy,
  }) : translationMap = lazy
            ? {
                utils.baseLocale: utils.baseLocale.buildSync(),
              }
            : {
                for (final locale in utils.locales) locale: locale.buildSync(),
              };

  /// Updates the provider state and therefore triggers a rebuild
  /// on all widgets listening to this provider.
  ///
  /// This is a flutter feature.
  /// This method will be overridden by slang_flutter.
  void updateProviderState(BaseAppLocale locale) {}
}

// We use extension methods here to have a workaround for static members of the same name
extension LocaleSettingsExt<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> on BaseLocaleSettings<E, T> {
  /// Returns true if the translations of the given [locale] are loaded.
  bool isLocaleLoaded(E locale) {
    return translationMap.containsKey(locale);
  }

  /// Loads the translations of the given [locale] if not already loaded.
  Future<void> loadLocale(E locale) async {
    if (translationMap.containsKey(locale)) {
      // already loaded
      return;
    }

    if (translationsLoading.contains(locale)) {
      // already loading
      return;
    }

    translationsLoading.add(locale);
    translationMap[locale] = await locale.build();
    translationsLoading.remove(locale);
  }

  /// Sync version of [loadLocale].
  void loadLocaleSync(E locale) {
    if (translationMap.containsKey(locale)) {
      // already loaded
      return;
    }

    translationMap[locale] = locale.buildSync();
  }

  /// Loads all locales.
  Future<void> loadAllLocales() async {
    for (final locale in utils.locales) {
      await loadLocale(locale);
    }
  }

  /// Sync version of [loadAllLocales].
  void loadAllLocalesSync() {
    for (final locale in utils.locales) {
      loadLocaleSync(locale);
    }
  }

  /// Gets the current locale.
  E get currentLocale {
    final locale = GlobalLocaleState.instance.getLocale();
    return utils.parseAppLocale(locale);
  }

  /// Gets the current translations.
  /// Falls back to the base locale if the current locale is not loaded.
  T get currentTranslations {
    return translationMap[currentLocale] ?? translationMap[utils.baseLocale]!;
  }

  /// Gets the translations of the given [locale].
  /// Falls back to the base locale if the given locale is not loaded.
  T getTranslations(E locale) {
    return translationMap[locale] ?? translationMap[utils.baseLocale]!;
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
  Future<E> setLocale(E locale, {bool? listenToDeviceLocale = false}) async {
    await loadLocale(locale);
    return _setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
  }

  /// Sync version of [setLocale].
  E setLocaleSync(E locale, {bool? listenToDeviceLocale = false}) {
    loadLocaleSync(locale);
    return _setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
  }

  E _setLocale(locale, {required bool? listenToDeviceLocale}) {
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
  Future<E> setLocaleRaw(
    String rawLocale, {
    bool? listenToDeviceLocale = false,
  }) async {
    final E locale = utils.parse(rawLocale);
    return await setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
  }

  /// Sync version of [setLocaleRaw].
  E setLocaleRawSync(String rawLocale, {bool? listenToDeviceLocale = false}) {
    final E locale = utils.parse(rawLocale);
    return setLocaleSync(locale, listenToDeviceLocale: listenToDeviceLocale);
  }

  /// Sets plural resolvers.
  /// See https://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html
  /// See https://github.com/slang-i18n/slang/blob/main/slang/lib/api/plural_resolver_map.dart
  /// Either specify [language], or [locale]. [locale] has precedence.
  Future<void> setPluralResolver({
    String? language,
    E? locale,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) async {
    final List<E> targetLocales = _getTargetLocales(
      language: language,
      locale: locale,
    );

    // update translation instances
    for (final curr in targetLocales) {
      await loadLocale(curr);
      final overrides = translationMap[curr]!.$meta.overrides;
      translationMap[curr] = await curr.build(
        // keep old overrides
        overrides: overrides.isNotEmpty ? overrides : null,
        cardinalResolver: cardinalResolver,
        ordinalResolver: ordinalResolver,
      );
    }
  }

  /// Sync version of [setPluralResolver].
  void setPluralResolverSync({
    String? language,
    E? locale,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) async {
    final List<E> targetLocales = _getTargetLocales(
      language: language,
      locale: locale,
    );

    // update translation instances
    for (final curr in targetLocales) {
      loadLocaleSync(curr);
      final overrides = translationMap[curr]!.$meta.overrides;
      translationMap[curr] = curr.buildSync(
        // keep old overrides
        overrides: overrides.isNotEmpty ? overrides : null,
        cardinalResolver: cardinalResolver,
        ordinalResolver: ordinalResolver,
      );
    }
  }

  List<E> _getTargetLocales({
    String? language,
    E? locale,
  }) {
    if (locale != null) {
      // take only this locale
      return [locale];
    } else if (language != null) {
      // map to language
      return utils.locales.where((l) => l.languageCode == language).toList();
    } else {
      throw 'Either language or locale must be specified';
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
  Future<void> overrideTranslations({
    required E locale,
    required FileType fileType,
    required String content,
  }) async {
    final currentMetadata = translationMap[locale]!.$meta;
    translationMap[locale] = await utils.buildWithOverrides(
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

  /// Sync version of [overrideTranslations].
  void overrideTranslationsSync({
    required E locale,
    required FileType fileType,
    required String content,
  }) {
    final currentMetadata = translationMap[locale]!.$meta;
    translationMap[locale] = utils.buildWithOverridesSync(
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
  Future<void> overrideTranslationsFromMap({
    required E locale,
    required bool isFlatMap,
    required Map map,
  }) async {
    final currentMetadata = translationMap[locale]!.$meta;
    translationMap[locale] = await utils.buildWithOverridesFromMap(
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

  /// Sync version of [overrideTranslationsFromMap].
  void overrideTranslationsFromMapSync({
    required E locale,
    required bool isFlatMap,
    required Map map,
  }) {
    final currentMetadata = translationMap[locale]!.$meta;
    translationMap[locale] = utils.buildWithOverridesFromMapSync(
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
