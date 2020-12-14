library fast_i18n;

import 'dart:io';

import 'package:fast_i18n/utils.dart';

class FastI18n {

  /// returns the locale string used by the device
  static String getDeviceLocale() {
    return Platform.localeName;
  }

  /// returns the candidate (or part of it) if it is supported
  /// fallback to base locale
  static String selectLocale(String candidate, List<String> supported, String baseLocale) {
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
