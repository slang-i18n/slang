import 'package:fast_i18n/app_locale_id_mapper.dart';
import 'package:fast_i18n/fast_i18n.dart';
import 'package:fast_i18n/global_locale_state.dart';

class BaseLocaleSettings<E, T extends BaseTranslations> {
  /// Locale enums sorted alphabetically and base locale first
  final List<E> locales;

  /// The base locale
  final E baseLocale;

  /// Internal: Mapping between [AppLocaleId] and [E]
  final AppLocaleIdMapper mapper;

  /// Internal: Manages all translation instances
  /// May be modified when setting a custom plural resolver
  final Map<E, T> translationMap;

  /// Internal: Reference to utils instance
  final BaseAppLocaleUtils utils;

  BaseLocaleSettings({
    required this.locales,
    required this.baseLocale,
    required this.mapper,
    required this.translationMap,
    required this.utils,
  });

  /// Sets locale, *but* do not change potential TranslationProvider's state
  /// Useful when you are in a pure Dart environment (without Flutter)
  E setLocaleExceptProvider(E locale) {
    GlobalLocaleState.instance.setLocaleId(mapper.toId(locale));
    return locale;
  }

  /// Gets current locale.
  E get currentLocale {
    final localeId = GlobalLocaleState.instance.getLocaleId();
    return mapper.toEnum(localeId) ?? baseLocale;
  }

  /// Gets current translations
  T get currentTranslations {
    return translationMap[currentLocale]!;
  }

  /// Gets supported locales in string format.
  List<String> get supportedLocalesRaw {
    return locales.map((locale) => mapper.toId(locale).languageTag).toList();
  }

  /// Sets plural resolvers.
  /// See https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html
  /// See https://github.com/Tienisto/flutter-fast-i18n/blob/master/lib/src/model/pluralization_resolvers.dart
  /// Either specify [language], or [locale]. Locale has precedence.
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
      targetLocales = locales
          .where((l) => mapper.toId(l).languageCode == language)
          .toList();
    } else {
      throw 'Either language or locale must be specified';
    }

    // update translation instances
    for (final curr in targetLocales) {
      translationMap[curr] = translationMap[curr]!.copyWith(
        cardinalResolver: cardinalResolver,
        ordinalResolver: ordinalResolver,
      ) as T;
    }
  }
}
