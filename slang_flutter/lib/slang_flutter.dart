import 'package:slang/api/state.dart';
import 'package:slang/slang.dart';
import 'package:flutter/widgets.dart';

export 'package:slang/slang.dart';

extension ExtAppLocaleUtils<E extends BaseAppLocale<T>,
    T extends BaseTranslations> on BaseAppLocaleUtils<E, T> {
  /// Returns the locale of the device.
  /// Fallbacks to base locale.
  E findDeviceLocale() {
    final String? deviceLocale =
        WidgetsBinding.instance.window.locale.toLanguageTag();
    if (deviceLocale == null) {
      return baseLocale;
    }
    return parse(deviceLocale);
  }
}

extension ExtAppLocale on BaseAppLocale {
  Locale get flutterLocale {
    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
    );
  }
}

/// Similar to [BaseLocaleSettings] but allows for specific overwrites
/// e.g. setLocale now also updates the provider
class BaseFlutterLocaleSettings<E extends BaseAppLocale<T>,
    T extends BaseTranslations> extends BaseLocaleSettings<E, T> {
  BaseFlutterLocaleSettings({
    required super.locales,
    required super.baseLocale,
    required super.utils,
  });
}

extension ExtBaseLocaleSettings<E extends BaseAppLocale<T>,
    T extends BaseTranslations> on BaseFlutterLocaleSettings<E, T> {
  /// Uses locale of the device, fallbacks to base locale.
  /// Returns the locale which has been set.
  E useDeviceLocale() {
    final E locale = utils.findDeviceLocale();
    return setLocale(locale);
  }

  /// Sets locale
  /// Returns the locale which has been set.
  E setLocale(E locale) {
    GlobalLocaleState.instance.setLocale(locale);

    _translationProviderKey.currentState?.setLocale(
      newLocale: locale,
      newTranslations: translationMap[locale]!,
    );

    return locale;
  }

  /// Sets locale using string tag (e.g. en_US, de-DE, fr)
  /// Fallbacks to base locale.
  /// Returns the locale which has been set.
  E setLocaleRaw(String rawLocale) {
    final E locale = utils.parse(rawLocale);
    return setLocale(locale);
  }

  /// Gets supported locales (as Locale objects) with base locale sorted first.
  List<Locale> get supportedLocales {
    return locales.map((locale) => locale.flutterLocale).toList();
  }
}

final _translationProviderKey = GlobalKey<_TranslationProviderState>();

abstract class BaseTranslationProvider<E extends BaseAppLocale<T>,
    T extends BaseTranslations> extends StatefulWidget {
  final E initLocale;
  final T initTranslations;

  BaseTranslationProvider({
    required this.initLocale,
    required this.initTranslations,
    required this.child,
  }) : super(key: _translationProviderKey);

  final Widget child;

  @override
  _TranslationProviderState<E, T> createState() =>
      _TranslationProviderState<E, T>(
        locale: initLocale,
        translations: initTranslations,
      );
}

class _TranslationProviderState<E extends BaseAppLocale<T>,
    T extends BaseTranslations> extends State<BaseTranslationProvider<E, T>> {
  E locale;
  T translations;

  _TranslationProviderState({
    required this.locale,
    required this.translations,
  });

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

class InheritedLocaleData<E extends BaseAppLocale<T>,
    T extends BaseTranslations> extends InheritedWidget {
  final E locale;
  final T translations;

  // shortcut
  Locale get flutterLocale => locale.flutterLocale;

  InheritedLocaleData({
    required this.locale,
    required this.translations,
    required super.child,
  });

  static InheritedLocaleData<E, T>
      of<E extends BaseAppLocale<T>, T extends BaseTranslations>(
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
    return !locale.sameLocale(oldWidget.locale);
  }
}

typedef InlineSpanBuilder = InlineSpan Function(String);
