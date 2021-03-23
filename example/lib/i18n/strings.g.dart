
// Generated file. Do not edit.

import 'package:flutter/material.dart';
import 'package:fast_i18n/fast_i18n.dart';

const String _baseLocale = 'en';

String _locale = _baseLocale;

Map<String, Strings> _strings = {
	'de': StringsDe.instance,
	'en': Strings.instance,
};

/// Method A: Simple
///
/// Widgets using this method will not be updated when locale changes during runtime.
/// Translation happens during initialization of the widget (call of t).
///
/// Usage:
/// String translated = t.someKey.anotherKey;
Strings _t = _strings[_locale]!;
Strings get t => _t;

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
/// final t = Translations.of(context); // get t variable
/// String translated = t.someKey.anotherKey; // use t variable
class Translations {
	Translations._(); // no constructor

	static Strings of(BuildContext context) {
		final inheritedWidget = context.dependOnInheritedWidgetOfExactType<_InheritedLocaleData>();
		if (inheritedWidget == null) {
			throw('Please wrap your app with "TranslationProvider".');
		}
		return _strings[inheritedWidget.locale]!;
	}
}

/// Type-safe locales
///
/// Usage:
/// - LocaleSettings.setLocaleTyped(AppLocale.en)
/// - if (LocaleSettings.currentLocaleTyped == AppLocale.en)
enum AppLocale {
	de,
	en,
}

class LocaleSettings {
	LocaleSettings._(); // no constructor

	/// Uses locale of the device, fallbacks to base locale.
	/// Returns the locale which has been set.
	/// Be aware that the locales are case sensitive.
	static String useDeviceLocale() {
		String deviceLocale = FastI18n.getDeviceLocale() ?? _baseLocale;
		return setLocale(deviceLocale);
	}

	/// Sets locale, fallbacks to base locale.
	/// Returns the locale which has been set.
	/// Be aware that the locales are case sensitive.
	static String setLocale(String locale) {
		_locale = FastI18n.selectLocale(locale, _strings.keys.toList(), _baseLocale);
		_t = _strings[_locale]!;

		final state = _translationProviderKey.currentState;
		if (state != null) {
			state.setLocale(_locale);
		}

		return _locale;
	}

	/// Typed version of [setLocale]
	static AppLocale setLocaleTyped(AppLocale locale) {
		return setLocale(locale.toLanguageTag()).toAppLocale()!;
	}

	/// Gets current locale.
	static String get currentLocale {
		return _locale;
	}

	/// Typed version of [currentLocale]
	static AppLocale get currentLocaleTyped {
		return _locale.toAppLocale()!;
	}

	/// Gets base locale.
	static String get baseLocale {
		return _baseLocale;
	}

	/// Gets supported locales.
	static List<String> get locales {
		return _strings.keys.toList();
	}

	/// Get supported locales with base locale sorted first.
	static List<Locale> get supportedLocales {
		return FastI18n.convertToLocales(_strings.keys.toList(), _baseLocale);
	}
}

// extensions for AppLocale

extension AppLocaleExtensions on AppLocale {
	String toLanguageTag() {
		switch (this) {
			case AppLocale.de: return 'de';
			case AppLocale.en: return 'en';
		}
	}
}
extension StringAppLocaleExtensions on String {
	AppLocale? toAppLocale() {
		switch (this) {
			case 'de': return AppLocale.de;
			case 'en': return AppLocale.en;
			default: return null;
		}
	}
}

// wrappers

GlobalKey<_TranslationProviderState> _translationProviderKey = new GlobalKey<_TranslationProviderState>();

class TranslationProvider extends StatefulWidget {
	TranslationProvider({required this.child}) : super(key: _translationProviderKey);

	final Widget child;

	@override
	_TranslationProviderState createState() => _TranslationProviderState();
}

class _TranslationProviderState extends State<TranslationProvider> {
	String locale = _locale;

	void setLocale(String newLocale) {
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
	final String locale;
	_InheritedLocaleData({required this.locale, required Widget child}) : super(child: child);

	@override
	bool updateShouldNotify(_InheritedLocaleData oldWidget) {
		return oldWidget.locale != locale;
	}
}

// translations

class StringsDe implements Strings {
	StringsDe._(); // no constructor

	static StringsDe _instance = StringsDe._();
	static StringsDe get instance => _instance;

	@override StringsMainScreenDe get mainScreen => StringsMainScreenDe._instance;
	@override Map<String, String> get locales => {
		'en': 'Englisch',
		'de': 'Deutsch',
	};
}

class StringsMainScreenDe implements StringsMainScreen {
	StringsMainScreenDe._(); // no constructor

	static StringsMainScreenDe _instance = StringsMainScreenDe._();
	static StringsMainScreenDe get instance => _instance;

	@override String title = 'Ein deutscher Titel';
	@override String counter({required Object count}) => 'Du hast $count mal gedrückt.';
	@override String tapMe = 'Drück mich';
}

class Strings {
	Strings._(); // no constructor

	static Strings _instance = Strings._();
	static Strings get instance => _instance;

	StringsMainScreen get mainScreen => StringsMainScreen._instance;
	Map<String, String> get locales => {
		'en': 'English',
		'de': 'German',
	};
}

class StringsMainScreen {
	StringsMainScreen._(); // no constructor

	static StringsMainScreen _instance = StringsMainScreen._();
	static StringsMainScreen get instance => _instance;

	String title = 'An English Title';
	String counter({required Object count}) => 'You pressed $count times.';
	String tapMe = 'Tap me';
}
