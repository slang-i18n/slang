library fast_i18n;

import 'package:devicelocale/devicelocale.dart';

class FastI18n {

  /// returns the locale string used by the device
  /// it always matches one of the supported locales
  /// fallback to '' (default locale)
  static Future<String> findDeviceLocale(List<String> supported) async {
    String deviceLocale = await Devicelocale.currentLocale;

    // 1st try: match exactly
    String selected = supported.firstWhere((element) => element == deviceLocale, orElse: () => null);
    if (selected != null)
      return selected;

    // 2nd try: match the first part
    String deviceLocaleFirstPart = deviceLocale.split('_').first;
    selected = supported.firstWhere((element) => element == deviceLocaleFirstPart, orElse: () => null);
    if (selected != null)
      return selected;

    // fallback: default locale
    return '';
  }
}