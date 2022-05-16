import 'package:collection/collection.dart';
import 'package:slang/api/locale.dart';
import 'package:slang/api/pluralization.dart';
import 'package:slang/api/state.dart';
import 'package:slang/builder/utils/regex_utils.dart';

/// Provides utility functions without any side effects.
abstract class BaseAppLocaleUtils<E extends BaseAppLocale<T>,
    T extends BaseTranslations> {
  /// Internal: The base locale
  final E baseLocale;

  /// Internal: All locales, unordered
  final List<E> locales;

  BaseAppLocaleUtils({
    required this.baseLocale,
    required this.locales,
  });
}

// We use extension methods here to have a workaround for static members of the same name
extension AppLocaleUtilsExt<E extends BaseAppLocale<T>,
    T extends BaseTranslations> on BaseAppLocaleUtils<E, T> {
  /// Parses the raw locale to get the enum.
  /// Fallbacks to base locale.
  E parse(String rawLocale) {
    final match = RegexUtils.localeRegex.firstMatch(rawLocale);
    E? selected;
    if (match != null) {
      final language = match.group(1);
      final country = match.group(3);

      // match exactly
      selected = locales.firstWhereOrNull((supported) =>
          supported.languageTag == rawLocale.replaceAll('_', '-'));

      if (selected == null && language != null) {
        // match language
        selected = locales.firstWhereOrNull(
            (supported) => supported.languageCode == language);
      }

      if (selected == null && country != null) {
        // match country
        selected = locales
            .firstWhereOrNull((supported) => supported.countryCode == country);
      }
    }

    return selected ?? baseLocale;
  }

  /// Gets the [E] type of [locale].
  ///
  /// [locale] may have a locale which is unsupported by [E].
  /// In this case, the base locale will be returned.
  E parseAppLocale(BaseAppLocale locale) {
    E? selected;

    // match exactly
    selected = locales.firstWhereOrNull((supported) => supported == locale);

    if (selected == null) {
      // match language
      selected = locales.firstWhereOrNull((supported) {
        return supported.languageCode == locale.languageCode;
      });
    }

    if (selected == null && locale.countryCode != null) {
      // match country
      selected = locales.firstWhereOrNull((supported) {
        return supported.countryCode == locale.countryCode;
      });
    }

    return selected ?? baseLocale;
  }
}

abstract class BaseLocaleSettings<E extends BaseAppLocale<T>,
    T extends BaseTranslations> {
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
}

// We use extension methods here to have a workaround for static members of the same name
extension LocaleSettingsExt<E extends BaseAppLocale<T>,
    T extends BaseTranslations> on BaseLocaleSettings<E, T> {
  /// Gets current locale.
  E get currentLocale {
    final locale = GlobalLocaleState.instance.getLocale();
    if (locale is E) {
      return locale; // take it directly
    } else {
      return utils.parseAppLocale(locale); // parse it
    }
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
      targetLocales = locales.where((l) => l.languageCode == language).toList();
    } else {
      throw 'Either language or locale must be specified';
    }

    // update translation instances
    for (final curr in targetLocales) {
      translationMap[curr] = curr.build(
        cardinalResolver: cardinalResolver,
        ordinalResolver: ordinalResolver,
      );
    }
  }
}

Map<E, T> _buildMap<E extends BaseAppLocale<T>, T extends BaseTranslations>(
    List<E> locales) {
  return <E, T>{
    for (final key in locales) key: key.build(),
  };
}
