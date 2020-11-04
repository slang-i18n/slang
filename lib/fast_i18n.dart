library fast_i18n;

import 'package:fast_i18n/utils.dart';
import 'package:flutter/widgets.dart';

class FastI18n {
  /// returns the locale string used by the device
  /// it always matches one of the supported locales
  /// fallback to '' (default locale)
  static Future<String> findDeviceLocale(List<String> supported,
      [String baseLocale = '']) async {
    String deviceLocale = WidgetsBinding.instance.window.locale.languageCode;

    return selectLocale(deviceLocale, supported, baseLocale);
  }

  /// returns the candidate (or part of it) if it is supported
  /// fallback to '' (default locale)
  static String selectLocale(String candidate, List<String> supported,
      [String baseLocale = '']) {
    // normalize
    candidate = Utils.normalize(candidate);

    // 1st try: match exactly
    String selected = supported.firstWhere((element) => element == candidate,
        orElse: () => null);
    if (selected != null) return selected;

    // 2nd try: match the first part (language)
    List<String> deviceLocaleParts = candidate.split('-');
    selected = supported.firstWhere(
        (element) => element == deviceLocaleParts.first,
        orElse: () => null);
    if (selected != null) return selected;

    // 3rd try: match the second part (region)
    selected = supported.firstWhere(
        (element) => element == deviceLocaleParts.last,
        orElse: () => null);
    if (selected != null) return selected;

    // fallback: default locale
    return baseLocale;
  }
}
