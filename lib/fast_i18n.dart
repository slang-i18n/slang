library fast_i18n;

import 'package:flutter/widgets.dart';
import 'package:fast_i18n/utils.dart';

class FastI18n {
  static const _localePartsDelimiter = '-';

  /// Returns the locale string used by the device.
  static String? getDeviceLocale() =>
      WidgetsBinding.instance?.window.locale.toLanguageTag();

  /// Returns the candidate (or part of it) if it is supported.
  /// Fallbacks to base locale.
  /// Please note that locales are case sensitive.
  static String selectLocale(
      String candidate, List<String> supported, String baseLocale) {
    // normalize
    candidate = Utils.normalize(candidate);

    // 1st try: match exactly
    String? selected = supported
        .cast<String?>()
        .firstWhere((element) => element == candidate, orElse: () => null);
    if (selected != null) return selected;

    // 2nd try: match the first part (language)
    List<String> deviceLocaleParts = candidate.split(_localePartsDelimiter);
    String deviceLocaleLanguage = deviceLocaleParts.first;
    selected = supported.cast<String?>().firstWhere(
        (element) => element?.startsWith(deviceLocaleLanguage) == true,
        orElse: () => null);
    if (selected != null) return selected;

    // fallback: default locale
    return baseLocale;
  }
}
