import 'package:fast_i18n_dart/fast_i18n_dart.dart';
import 'package:flutter/widgets.dart';

extension ExtBaseAppLocale on BaseAppLocale {
  Locale get flutterLocale {
    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
    );
  }
}

extension ExtBaseLocaleSettings<T extends BaseAppLocale> on BaseLocaleSettings<T> {
  /// Uses locale of the device, fallbacks to base locale.
  /// Returns the locale which has been set.
  T useDeviceLocale() {
    final locale = AppLocaleUtils(localeValues).findDeviceLocale() ?? baseLocale;
    return setLocale(locale);
  }

  /// Sets locale
  /// Returns the locale which has been set.
  T setLocale(T locale) {
    setLocaleExceptProvider(locale);

    if (WidgetsBinding.instance != null) {
      // force rebuild if TranslationProvider is used
      _translationProviderKey.currentState?.setLocale(locale);
    }

    return locale;
  }

  /// Sets locale using string tag (e.g. en_US, de-DE, fr)
  /// Fallbacks to base locale.
  /// Returns the locale which has been set.
  T setLocaleRaw(String rawLocale) {
    final locale = AppLocaleUtils(localeValues).parse(rawLocale) ?? baseLocale;
    return setLocale(locale);
  }

  /// Gets supported locales (as Locale objects) with base locale sorted first.
  List<Locale> get supportedLocales {
    return localeValues.map((locale) => locale.flutterLocale).toList();
  }
}

extension ExtAppLocaleUtils<T extends BaseAppLocale> on AppLocaleUtils<T> {
  /// Returns the locale of the device as the enum type.
  /// Fallbacks to base locale.
  T? findDeviceLocale() {
    final String? deviceLocale = WidgetsBinding.instance?.window.locale.toLanguageTag();
    if (deviceLocale == null) return null;
    return selectLocale(deviceLocale);
  }
}

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class Translations {
  Translations._(); // no constructor

  static _StringsZh of(BuildContext context) {
    final inheritedWidget = context.dependOnInheritedWidgetOfExactType<_InheritedLocaleData>();
    if (inheritedWidget == null) {
      throw 'Please wrap your app with "TranslationProvider".';
    }
    return inheritedWidget.translations;
  }
}

final _translationProviderKey = GlobalKey<_TranslationProviderState>();

class TranslationProvider extends StatefulWidget {
  TranslationProvider({required this.child}) : super(key: _translationProviderKey);

  final Widget child;

  @override
  _TranslationProviderState createState() => _TranslationProviderState();

  static _InheritedLocaleData of(BuildContext context) {
    final inheritedWidget = context.dependOnInheritedWidgetOfExactType<_InheritedLocaleData>();
    if (inheritedWidget == null) {
      throw 'Please wrap your app with "TranslationProvider".';
    }
    return inheritedWidget;
  }
}

class _TranslationProviderState extends State<TranslationProvider> {
  BaseAppLocale locale = _currLocale;

  void setLocale(BaseAppLocale newLocale) {
    setState(() {
      locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedLocaleData(
      locale: locale,
      child: widget.child,
    );
  }
}

class _InheritedLocaleData extends InheritedWidget {
  final BaseAppLocale locale;

  Locale get flutterLocale => locale.flutterLocale; // shortcut
  final _StringsZh translations; // store translations to avoid switch call

  _InheritedLocaleData({required this.locale, required Widget child})
      : translations = locale.translations,
        super(child: child);

  @override
  bool updateShouldNotify(_InheritedLocaleData oldWidget) {
    return oldWidget.locale != locale;
  }
}
