import 'package:fast_i18n/api/app_locale_id.dart';
import 'package:fast_i18n/api/app_locale_id_mapper.dart';

final _localeRegex =
    RegExp(r'^([a-z]{2,8})?([_-]([A-Za-z]{4}))?([_-]?([A-Z]{2}|[0-9]{3}))?$');

/// Provides utility functions without any side effects.
abstract class BaseAppLocaleUtils<E> {
  /// Internal: Mapping between [AppLocaleId] and [E]
  final AppLocaleIdMapper<E> mapper;

  /// Internal: The base locale
  final E baseLocale;

  /// Internal: [AppLocaleId] list, unordered
  final List<AppLocaleId> localeIds;

  BaseAppLocaleUtils({
    required this.mapper,
    required this.baseLocale,
  }) : localeIds = mapper.getLocaleIds();
}

// We use extension methods here to have a workaround for static members of the same name
extension AppLocaleUtilsExt<E> on BaseAppLocaleUtils<E> {
  /// Parses the raw locale to get the enum.
  /// Fallbacks to base locale.
  E parse(String rawLocale) {
    final match = _localeRegex.firstMatch(rawLocale);
    AppLocaleId? selected;
    if (match != null) {
      final language = match.group(1);
      final country = match.group(5);

      // match exactly
      selected = localeIds.cast<AppLocaleId?>().firstWhere(
          (supported) =>
              supported?.languageTag == rawLocale.replaceAll('_', '-'),
          orElse: () => null);

      if (selected == null && language != null) {
        // match language
        selected = localeIds.cast<AppLocaleId?>().firstWhere(
            (supported) => supported?.languageTag.startsWith(language) == true,
            orElse: () => null);
      }

      if (selected == null && country != null) {
        // match country
        selected = localeIds.cast<AppLocaleId?>().firstWhere(
            (supported) => supported?.languageTag.contains(country) == true,
            orElse: () => null);
      }
    }

    if (selected == null) {
      return baseLocale;
    }

    return mapper.toEnum(selected) ?? baseLocale;
  }
}
