import 'package:fast_i18n/api/app_locale_id.dart';

/// The [GlobalLocaleState] storing the global locale.
/// It is *shared* among all packages of an app.
class GlobalLocaleState {
  GlobalLocaleState._();

  static GlobalLocaleState instance = GlobalLocaleState._();

  AppLocaleId _currLocaleId = AppLocaleId.UNDEFINED_LANGUAGE;

  AppLocaleId getLocaleId() {
    return _currLocaleId;
  }

  void setLocaleId(AppLocaleId localeId) {
    _currLocaleId = localeId;
  }
}
