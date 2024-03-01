import 'package:flutter/widgets.dart';
import 'package:slang/api/translation_overrides.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/model/pluralization.dart';
import 'package:slang/slang.dart';

export 'package:slang/slang.dart';

part 'translation_overrides_flutter.dart';

typedef InlineSpanBuilder = InlineSpan Function(String);

extension ExtAppLocaleUtils<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> on BaseAppLocaleUtils<E, T> {
  /// Returns the locale of the device.
  /// Fallbacks to base locale.
  E findDeviceLocale() {
    final Locale deviceLocale =
        WidgetsBinding.instance.platformDispatcher.locale;
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

/// Similar to [BaseLocaleSettings] but actually implements
/// the [updateProviderState] method.
class BaseFlutterLocaleSettings<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> extends BaseLocaleSettings<E, T> {
  BaseFlutterLocaleSettings({
    required super.utils,
  });

  @override
  void updateProviderState(BaseAppLocale locale) {
    for (final key in _GlobalKeyHandler.instance._globalKeys.values) {
      (key.currentState as _TranslationProviderState?)?.updateState(locale);
    }
  }
}

extension ExtBaseLocaleSettings<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> on BaseFlutterLocaleSettings<E, T> {
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

abstract class BaseTranslationProvider<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> extends StatefulWidget {
  final T initTranslations;
  final BaseFlutterLocaleSettings<E, T> settings;

  BaseTranslationProvider({
    required this.settings,
    required this.child,
  })  : initTranslations = settings.currentTranslations,
        super(
          key: _GlobalKeyHandler.instance.register<E, T>(
            baseLocale: settings.utils.baseLocale,
          ),
        );

  final Widget child;

  @override
  _TranslationProviderState<E, T> createState() =>
      _TranslationProviderState<E, T>(initTranslations);
}

class _TranslationProviderState<E extends BaseAppLocale<E, T>,
        T extends BaseTranslations<E, T>>
    extends State<BaseTranslationProvider<E, T>> with WidgetsBindingObserver {
  T translations;

  _TranslationProviderState(this.translations);

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

    // [updateState] will be called by these setLocale methods internally.
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
      this.translations = widget.settings.translationMap[localeTyped]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedLocaleData<E, T>(
      translations: translations,
      child: widget.child,
    );
  }
}

class InheritedLocaleData<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> extends InheritedWidget {
  /// The current translations.
  final T translations;

  /// The current locale of the translations.
  E get locale => translations.$meta.locale;

  /// The current locale but as flutter locale.
  Locale get flutterLocale => locale.flutterLocale;

  InheritedLocaleData({
    required this.translations,
    required super.child,
  });

  static InheritedLocaleData<E, T>
      of<E extends BaseAppLocale<E, T>, T extends BaseTranslations<E, T>>(
          BuildContext context) {
    final inheritedWidget =
        context.dependOnInheritedWidgetOfExactType<InheritedLocaleData<E, T>>();
    if (inheritedWidget == null) {
      throw 'Please wrap your app with "TranslationProvider".';
    }
    return inheritedWidget;
  }

  @override
  bool updateShouldNotify(InheritedLocaleData<E, T> oldWidget) {
    // only rebuild if translations differ
    return !identical(translations, oldWidget.translations);
  }
}

class _GlobalKeyHandler {
  _GlobalKeyHandler._();

  /// Singleton instance
  static final _GlobalKeyHandler instance = _GlobalKeyHandler._();

  /// We need the global keys to be able to trigger rebuilds.
  ///
  /// The [BaseAppLocale] key instance is needed to avoid registering
  /// the same [TranslationProvider] multiple times.
  Map<BaseAppLocale, GlobalKey> _globalKeys = {};

  /// Registers a new global key for a specific generic type.
  GlobalKey<_TranslationProviderState<E, T>> register<
      E extends BaseAppLocale<E, T>, T extends BaseTranslations<E, T>>({
    required E baseLocale,
  }) {
    final existing = _globalKeys[baseLocale];
    if (existing != null) {
      // It seems that the constructor of [TranslationProvider] is called again.
      // This is why we need to return the existing key.
      // This happens if the developer constructs the [TranslationProvider]
      // in the build method of a widget.
      return existing as GlobalKey<_TranslationProviderState<E, T>>;
    }

    final key = GlobalKey<_TranslationProviderState<E, T>>();
    _globalKeys[baseLocale] = key;
    return key;
  }
}
