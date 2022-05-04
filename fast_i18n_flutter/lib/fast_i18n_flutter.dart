import 'package:fast_i18n/api/global_locale_state.dart';
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

/// Similar to [BaseLocaleSettings] but allows for specific overwrites
/// e.g. setLocale now also updates the provider
class BaseFlutterLocaleSettings<E, T extends BaseTranslations>
    extends BaseLocaleSettings<E, T> {
  BaseFlutterLocaleSettings({
    required List<E> locales,
    required E baseLocale,
    required AppLocaleIdMapper mapper,
    required Map<E, T> translationMap,
    required BaseAppLocaleUtils utils,
  }) : super(
          locales: locales,
          baseLocale: baseLocale,
          mapper: mapper,
          translationMap: translationMap,
          utils: utils,
        );
}

extension ExtBaseLocaleSettings<E, T extends BaseTranslations>
    on BaseFlutterLocaleSettings<E, T> {
  /// Uses locale of the device, fallbacks to base locale.
  /// Returns the locale which has been set.
  E useDeviceLocale() {
    final E locale = utils.findDeviceLocale();
    return setLocale(locale);
  }

  /// Sets locale
  /// Returns the locale which has been set.
  E setLocale(E locale) {
    GlobalLocaleState.instance.setLocaleId(mapper.toId(locale));

    if (WidgetsBinding.instance != null) {
      // force rebuild if TranslationProvider is used
      _translationProviderKey.currentState?.setLocale(
        newLocale: mapper.toId(locale),
        newTranslations: translationMap[locale]!,
      );
    }

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
    return locales.map((locale) => mapper.toId(locale).flutterLocale).toList();
  }
}

final _translationProviderKey = GlobalKey<_TranslationProviderState>();

abstract class BaseTranslationProvider<T extends BaseTranslations>
    extends StatefulWidget {
  final AppLocaleId baseLocaleId;
  final T baseTranslations;

  BaseTranslationProvider({
    required this.baseLocaleId,
    required this.baseTranslations,
    required this.child,
  }) : super(key: _translationProviderKey);

  final Widget child;

  @override
  _TranslationProviderState<T> createState() => _TranslationProviderState<T>(
        localeId: baseLocaleId,
        translations: baseTranslations,
      );
}

class _TranslationProviderState<T extends BaseTranslations>
    extends State<BaseTranslationProvider<T>> {
  AppLocaleId localeId;
  T translations;

  _TranslationProviderState({
    required this.localeId,
    required this.translations,
  });

  void setLocale({
    required AppLocaleId newLocale,
    required T newTranslations,
  }) {
    setState(() {
      localeId = newLocale;
      translations = newTranslations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedLocaleData(
      localeId: localeId,
      translations: translations,
      child: widget.child,
    );
  }
}

class InheritedLocaleData<T extends BaseTranslations> extends InheritedWidget {
  final AppLocaleId localeId;
  final T translations;

  // shortcut
  Locale get flutterLocale => localeId.flutterLocale;

  InheritedLocaleData({
    required this.localeId,
    required this.translations,
    required Widget child,
  }) : super(child: child);

  static InheritedLocaleData<T> of<T extends BaseTranslations>(
      BuildContext context) {
    final inheritedWidget =
        context.dependOnInheritedWidgetOfExactType<InheritedLocaleData<T>>();
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
