import 'package:fast_i18n_dart/fast_i18n_dart.dart';
import 'package:flutter/widgets.dart';

export 'package:fast_i18n_dart/fast_i18n_dart.dart';
export 'package:flutter/widgets.dart';

extension ExtAppLocaleId on AppLocaleId {
  Locale get flutterLocale {
    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
    );
  }
}

extension ExtBaseLocaleSettings on BaseLocaleSettings {
  /// Uses locale of the device, fallbacks to base locale.
  /// Returns the locale which has been set.
  AppLocaleId useDeviceLocale() {
    final locale =
        AppLocaleUtils(localeValues).findDeviceLocale() ?? baseLocaleId;
    return setLocale(locale);
  }

  /// Sets locale
  /// Returns the locale which has been set.
  AppLocaleId setLocale(AppLocaleId locale) {
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
  AppLocaleId setLocaleRaw(String rawLocale) {
    final locale = AppLocaleUtils(localeValues).parse(rawLocale) ?? baseLocaleId;
    return setLocale(locale);
  }

  /// Gets supported locales (as Locale objects) with base locale sorted first.
  List<Locale> get supportedLocales {
    return localeValues.map((locale) => locale.flutterLocale).toList();
  }
}

extension ExtAppLocaleUtils on AppLocaleUtils {
  /// Returns the locale of the device as the enum type.
  /// Fallbacks to base locale.
  AppLocaleId? findDeviceLocale() {
    final String? deviceLocale =
        WidgetsBinding.instance?.window.locale.toLanguageTag();
    if (deviceLocale == null) return null;
    return parse(deviceLocale);
  }
}

final _translationProviderKey = GlobalKey<_TranslationProviderState>();

class TranslationProvider extends StatefulWidget {
  TranslationProvider({required this.child})
      : super(key: _translationProviderKey);

  final Widget child;

  @override
  _TranslationProviderState createState() => _TranslationProviderState();

  static InheritedLocaleData of(BuildContext context) =>
      InheritedLocaleData.of(context);
}

class _TranslationProviderState extends State<TranslationProvider> {
  late AppLocaleId locale;

  @override
  void initState() {
    super.initState();
    locale = currLocaleId;
  }

  void setLocale(AppLocaleId newLocale) {
    setState(() {
      locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedLocaleData(
      localeId: locale,
      child: widget.child,
    );
  }
}

class InheritedLocaleData extends InheritedWidget {
  final AppLocaleId localeId;

  Locale get flutterLocale => localeId.flutterLocale; // shortcut

  InheritedLocaleData({required this.localeId, required Widget child})
      : super(child: child);

  static InheritedLocaleData of(BuildContext context) {
    final inheritedWidget =
        context.dependOnInheritedWidgetOfExactType<InheritedLocaleData>();
    if (inheritedWidget == null) {
      throw 'Please wrap your app with "TranslationProvider".';
    }
    return inheritedWidget;
  }

  @override
  bool updateShouldNotify(InheritedLocaleData oldWidget) {
    return oldWidget.localeId != localeId;
  }
}

typedef InlineSpanBuilder = InlineSpan Function(String);
