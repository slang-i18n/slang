import 'package:fast_i18n_dart/fast_i18n_dart.dart';
import 'package:flutter/widgets.dart';

export 'package:flutter/widgets.dart';

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

final _translationProviderKey = GlobalKey<_TranslationProviderState>();

class TranslationProvider extends StatefulWidget {
  TranslationProvider({required this.child}) : super(key: _translationProviderKey);

  final Widget child;

  @override
  _TranslationProviderState createState() => _TranslationProviderState();

  static InheritedLocaleData of(BuildContext context) => InheritedLocaleData.of(context);
}

class _TranslationProviderState extends State<TranslationProvider> {
  late BaseAppLocale locale;

  void setLocale(BaseAppLocale newLocale) {
    setState(() {
      locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedLocaleData(
      locale: locale,
      child: widget.child,
    );
  }
}

class InheritedLocaleData extends InheritedWidget {
  final BaseAppLocale locale;

  Locale get flutterLocale => locale.flutterLocale; // shortcut

  InheritedLocaleData({required this.locale, required Widget child}) : super(child: child);

  static InheritedLocaleData of(BuildContext context) {
    final inheritedWidget = context.dependOnInheritedWidgetOfExactType<InheritedLocaleData>();
    if (inheritedWidget == null) {
      throw 'Please wrap your app with "TranslationProvider".';
    }
    return inheritedWidget;
  }

  @override
  bool updateShouldNotify(InheritedLocaleData oldWidget) {
    return oldWidget.locale != locale;
  }
}
