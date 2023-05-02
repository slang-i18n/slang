import 'package:flutter/widgets.dart';
import 'package:slang/api/translation_overrides.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/model/pluralization.dart';
import 'package:slang/slang.dart';

export 'package:slang/slang.dart';

part 'translation_overrides_flutter.dart';

extension ExtAppLocaleUtils<E extends BaseAppLocale<E, T>, T extends BaseTranslations<E, T>>
    on BaseAppLocaleUtils<E, T> {
  /// Returns the locale of the device.
  /// Fallbacks to base locale.
  E findDeviceLocale() {
    final Locale deviceLocale = WidgetsBinding.instance.window.locale;
    return parseLocaleParts(
      languageCode: deviceLocale.languageCode,
      scriptCode: deviceLocale.scriptCode,
      countryCode: deviceLocale.countryCode,
    );
  }

  /// Gets supported locales (as Locale objects) with base locale sorted first.
  List<Locale> get supportedLocales {
    return locales.map((locale) => locale.flutterLocale).toList();
  }
}

extension ExtAppLocale on BaseAppLocale {
  /// Returns the locale type of the flutter framework.
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
class BaseFlutterLocaleSettings<E extends BaseAppLocale<E, T>, T extends BaseTranslations<E, T>>
    extends BaseLocaleSettings<E, T> {
  BaseFlutterLocaleSettings({
    required super.utils,
  });

  @override
  void updateProviderState(BaseAppLocale locale) {
    _translationProviderKey.currentState?.updateState(locale);
  }
}

extension ExtBaseLocaleSettings<E extends BaseAppLocale<E, T>, T extends BaseTranslations<E, T>>
    on BaseFlutterLocaleSettings<E, T> {
  /// Uses locale of the device, fallbacks to base locale.
  /// Returns the locale which has been set.
  E useDeviceLocale() {
    final E locale = utils.findDeviceLocale();
    return setLocale(locale, listenToDeviceLocale: true);
  }

  /// Gets supported locales (as Locale objects) with base locale sorted first.
  List<Locale> get supportedLocales {
    return utils.supportedLocales;
  }
}

final _translationProviderKey = GlobalKey<_TranslationProviderState>();

abstract class BaseTranslationProvider<E extends BaseAppLocale<E, T>, T extends BaseTranslations<E, T>>
    extends StatefulWidget {
  final E initLocale;
  final T initTranslations;
  final BaseFlutterLocaleSettings<E, T> settings;

  BaseTranslationProvider({
    required this.settings,
    required this.child,
  })  : initLocale = settings.currentLocale,
        initTranslations = settings.currentTranslations,
        super(key: _translationProviderKey);

  final Widget child;

  @override
  _TranslationProviderState<E, T> createState() => _TranslationProviderState<E, T>(
        locale: initLocale,
        translations: initTranslations,
        listenToDeviceLocale: false,
      );
}

class _TranslationProviderState<E extends BaseAppLocale<E, T>, T extends BaseTranslations<E, T>>
    extends State<BaseTranslationProvider<E, T>> with WidgetsBindingObserver {
  E locale;
  T translations;
  bool listenToDeviceLocale;

  _TranslationProviderState({
    required this.locale,
    required this.translations,
    required this.listenToDeviceLocale,
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);

    if (!widget.settings.listenToDeviceLocale || locales == null) {
      return;
    }

    if (locales.isEmpty) {
      widget.settings.setLocale(
        widget.settings.utils.baseLocale,
        listenToDeviceLocale: true, // keep listening to it
      );
    } else {
      widget.settings.setLocaleRaw(
        locales.first.toLanguageTag(),
        listenToDeviceLocale: true, // keep listening to it
      );
    }
  }

  /// Updates the provider state.
  /// Widgets listening to this provider will rebuild if [translations] differ.
  void updateState(BaseAppLocale locale) {
    final E localeTyped = widget.settings.utils.parseAppLocale(locale);
    setState(() {
      this.locale = localeTyped;
      this.translations = widget.settings.translationMap[localeTyped]!;
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

class InheritedLocaleData<E extends BaseAppLocale<E, T>, T extends BaseTranslations<E, T>> extends InheritedWidget {
  final E locale;
  final T translations;

  // shortcut
  Locale get flutterLocale => locale.flutterLocale;

  InheritedLocaleData({
    required this.locale,
    required this.translations,
    required super.child,
  });

  static InheritedLocaleData<E, T> of<E extends BaseAppLocale<E, T>, T extends BaseTranslations<E, T>>(
      BuildContext context) {
    final inheritedWidget = context.dependOnInheritedWidgetOfExactType<InheritedLocaleData<E, T>>();
    if (inheritedWidget == null) {
      throw 'Please wrap your app with "TranslationProvider".';
    }
    return inheritedWidget;
  }

  @override
  bool updateShouldNotify(InheritedLocaleData<E, T> oldWidget) {
    // we need to check the actual translations
    // because locale may be the same after overriding translations
    return !identical(translations, oldWidget.translations);
  }
}
