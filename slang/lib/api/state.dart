import 'dart:async';

import 'package:slang/api/locale.dart';

/// The [GlobalLocaleState] storing the global locale.
/// It is *shared* among all packages of an app.
class GlobalLocaleState {
  GlobalLocaleState._();

  /// The singleton instance.
  static final GlobalLocaleState instance = GlobalLocaleState._();

  /// The current locale.
  ///
  /// Initialized with [BaseAppLocale.undefinedLocale] which gets converted
  /// to the actual base locale of an app.
  BaseAppLocale _currLocale = BaseAppLocale.undefinedLocale;

  final _controller = StreamController<BaseAppLocale>.broadcast();

  /// Gets the current locale.
  ///
  /// This exposes the "raw" locale.
  /// [LocaleSettings] will convert this to the actual enum value which is also
  /// supported by the app.
  BaseAppLocale getLocale() {
    return _currLocale;
  }

  /// Sets the locale and notifies all listeners.
  void setLocale(BaseAppLocale locale) {
    if (locale == _currLocale) {
      return;
    }
    _currLocale = locale;
    _controller.add(locale);
  }

  /// Gets the stream of locale changes.
  ///
  /// This exposes the "raw" locale.
  /// [LocaleSettings] will convert this to the actual enum value which is also
  /// supported by the app.
  Stream<BaseAppLocale> getStream() {
    return _controller.stream;
  }
}
