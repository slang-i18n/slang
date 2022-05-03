import 'package:fast_i18n/fast_i18n.dart';
import 'package:flutter/widgets.dart';

export 'package:fast_i18n/fast_i18n.dart';
export 'package:flutter/widgets.dart';

extension ExtAppLocaleUtils<E> on BaseAppLocaleUtils<E> {
  /// Returns the locale of the device.
  /// Fallbacks to base locale.
  E findDeviceLocale() {
    final String? deviceLocale =
        WidgetsBinding.instance?.window.locale.toLanguageTag();
    if (deviceLocale == null) {
      return baseLocale;
    }
    return parse(deviceLocale);
  }
}

extension ExtAppLocaleId on AppLocaleId {
  Locale get flutterLocale {
    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
    );
  }
}

extension ExtBaseLocaleSettings<E, T extends BaseTranslations>
    on BaseLocaleSettings<E, T> {
  /// Uses locale of the device, fallbacks to base locale.
  /// Returns the locale which has been set.
  E useDeviceLocale() {
    final locale = utils.findDeviceLocale();
    return setLocale(locale);
  }

  /// Sets locale
  /// Returns the locale which has been set.
  E setLocale(E locale) {
    setLocaleExceptProvider(locale);

    if (WidgetsBinding.instance != null) {
      // force rebuild if TranslationProvider is used
      _translationProviderKey.currentState?.setLocale(
        newLocale: locale,
        newTranslations: translationMap[locale]!,
      );
    }

    return locale;
  }

  /// Sets locale using string tag (e.g. en_US, de-DE, fr)
  /// Fallbacks to base locale.
  /// Returns the locale which has been set.
  E setLocaleRaw(String rawLocale) {
    final locale = utils.parse(rawLocale);
    return setLocale(locale);
  }

  /// Gets supported locales (as Locale objects) with base locale sorted first.
  List<Locale> get supportedLocales {
    return locales.map((locale) => mapper.toId(locale).flutterLocale).toList();
  }
}

final _translationProviderKey = GlobalKey<_TranslationProviderState>();

abstract class BaseTranslationProvider<E, T extends BaseTranslations>
    extends StatefulWidget {
  final E baseLocale;
  final T baseTranslations;

  BaseTranslationProvider({
    required this.baseLocale,
    required this.baseTranslations,
    required this.child,
  }) : super(key: _translationProviderKey);

  final Widget child;

  @override
  _TranslationProviderState<E, T> createState() =>
      _TranslationProviderState<E, T>(
        locale: baseLocale,
        translations: baseTranslations,
      );
}

class _TranslationProviderState<E, T extends BaseTranslations>
    extends State<BaseTranslationProvider<E, T>> {
  E locale;
  T translations;

  _TranslationProviderState({required this.locale, required this.translations});

  void setLocale({
    required E newLocale,
    required T newTranslations,
  }) {
    setState(() {
      locale = newLocale;
      translations = newTranslations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedLocaleData(
      locale: locale,
      translations: translations,
      child: widget.child,
    );
  }
}

class InheritedLocaleData<E, T extends BaseTranslations>
    extends InheritedWidget {
  final E locale;
  final T translations;

  InheritedLocaleData({
    required this.locale,
    required this.translations,
    required Widget child,
  }) : super(child: child);

  static InheritedLocaleData<E, T> of<E, T extends BaseTranslations>(
      BuildContext context) {
    final inheritedWidget =
        context.dependOnInheritedWidgetOfExactType<InheritedLocaleData<E, T>>();
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

typedef InlineSpanBuilder = InlineSpan Function(String);
