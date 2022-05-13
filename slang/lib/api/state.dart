import 'package:slang/api/locale.dart';

/// The [GlobalLocaleState] storing the global locale.
/// It is *shared* among all packages of an app.
class GlobalLocaleState {
  GlobalLocaleState._();

  static GlobalLocaleState instance = GlobalLocaleState._();

  BaseAppLocale _currLocale = BaseAppLocale.undefinedLocale;

  BaseAppLocale getLocale() {
    return _currLocale;
  }

  void setLocale(BaseAppLocale locale) {
    _currLocale = locale;
  }
}
