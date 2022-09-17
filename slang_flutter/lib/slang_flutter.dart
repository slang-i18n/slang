import 'package:slang/api/translation_overrides.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/slang.dart';
import 'package:flutter/widgets.dart';

export 'package:slang/slang.dart';

extension ExtAppLocaleUtils<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> on BaseAppLocaleUtils<E, T> {
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
class BaseFlutterLocaleSettings<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> extends BaseLocaleSettings<E, T> {
  BaseFlutterLocaleSettings({
    required super.locales,
    required super.baseLocale,
    required super.utils,
  });

  @override
  updateProviderState(E locale, T translations) {
    _translationProviderKey.currentState?.setLocale(
      newLocale: locale,
      newTranslations: translations,
    );
  }
}

extension ExtBaseLocaleSettings<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> on BaseFlutterLocaleSettings<E, T> {
  /// Uses locale of the device, fallbacks to base locale.
  /// Returns the locale which has been set.
  E useDeviceLocale() {
    final E locale = utils.findDeviceLocale();
    return setLocale(locale);
  }

  /// Gets supported locales (as Locale objects) with base locale sorted first.
  List<Locale> get supportedLocales {
    return locales.map((locale) => locale.flutterLocale).toList();
  }
}

final _translationProviderKey = GlobalKey<_TranslationProviderState>();

abstract class BaseTranslationProvider<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> extends StatefulWidget {
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

class _TranslationProviderState<E extends BaseAppLocale<E, T>,
        T extends BaseTranslations<E, T>>
    extends State<BaseTranslationProvider<E, T>> {
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

class InheritedLocaleData<E extends BaseAppLocale<E, T>,
    T extends BaseTranslations<E, T>> extends InheritedWidget {
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
    // we need to check the actual translations
    // because locale may be the same after overriding translations
    return !identical(translations, oldWidget.translations);
  }
}

typedef InlineSpanBuilder = InlineSpan Function(String);

class TranslationOverridesFlutter {
  static TextSpan? rich(
      TranslationMetadata meta, String path, Map<String, Object> param) {
    final node = meta.overrides[path];

    if (node == null || node is! RichTextNode) {
      return null;
    }

    return TextSpan(
      children: node.spans.map((e) {
        if (e is LiteralSpan) {
          return TextSpan(
            text: e.literal.applyParamsAndLinks(meta, param),
          );
        }
        if (e is FunctionSpan) {
          return (param[e.functionName] as InlineSpanBuilder)(e.arg);
        }
        if (e is VariableSpan) {
          return param[e.variableName] as InlineSpan;
        }
        throw 'This should not happen';
      }).toList(),
    );
  }
}
