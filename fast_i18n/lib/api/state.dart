import 'package:fast_i18n/api/locale.dart';

/// The [GlobalLocaleState] storing the global locale.
/// It is *shared* among all packages of an app.
class GlobalLocaleState {
  GlobalLocaleState._();

  static GlobalLocaleState instance = GlobalLocaleState._();

  BaseAppLocale _currLocaleId = BaseAppLocale.UNDEFINED_LANGUAGE;

  BaseAppLocale getLocale() {
    return _currLocaleId;
  }

  void setLocale(BaseAppLocale locale) {
    _currLocaleId = locale;
  }
}
