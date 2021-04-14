
// Generated file. Do not edit.

import 'package:flutter/material.dart';
import 'package:fast_i18n/fast_i18n.dart';

const AppLocale _baseLocale = AppLocale.en;
AppLocale _currLocale = _baseLocale;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en)
/// - if (LocaleSettings.currentLocale == AppLocale.en)
enum AppLocale {
	de, // de 
	en, // en (base locale, fallback)
}

/// Method A: Simple
///
/// Widgets using this method will not be updated when locale changes during runtime.
/// Translation happens during initialization of the widget (call of t).
///
/// Usage:
/// String translated = t.someKey.anotherKey;
_Strings _t = _currLocale.translations;
_Strings get t => _t;

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

	static _Strings of(BuildContext context) {
		final inheritedWidget = context.dependOnInheritedWidgetOfExactType<_InheritedLocaleData>();
		if (inheritedWidget == null) {
			throw('Please wrap your app with "TranslationProvider".');
		}
		return inheritedWidget.locale.translations;
	}
}

class LocaleSettings {
	LocaleSettings._(); // no constructor

	/// Uses locale of the device, fallbacks to base locale.
	/// Returns the locale which has been set.
	/// Hint for pre 4.x.x developers: You can access the raw string via LocaleSettings.useDeviceLocale().languageTag
	static AppLocale useDeviceLocale() {
		String? deviceLocale = FastI18n.getDeviceLocale();
		if (deviceLocale != null)
			return setLocaleRaw(deviceLocale);
		else
			return setLocale(_baseLocale);
	}

	/// Sets locale
	/// Returns the locale which has been set.
	static AppLocale setLocale(AppLocale locale) {
		_currLocale = locale;
		_t = _currLocale.translations;

		final state = _translationProviderKey.currentState;
		if (state != null) {
			// force rebuild if TranslationProvider is used
			state.setLocale(_currLocale);
		}

		return _currLocale;
	}

	/// Sets locale using string tag (e.g. en_US, de-DE, fr)
	/// Fallbacks to base locale.
	/// Returns the locale which has been set.
	static AppLocale setLocaleRaw(String locale) {
		String selectedLocale = FastI18n.selectLocale(locale, supportedLocalesRaw, _baseLocale.languageTag);
		return setLocale(selectedLocale.toAppLocale()!);
	}

	/// Gets current locale.
	/// Hint for pre 4.x.x developers: You can access the raw string via LocaleSettings.currentLocale.languageTag
	static AppLocale get currentLocale {
		return _currLocale;
	}

	/// Gets base locale.
	/// Hint for pre 4.x.x developers: You can access the raw string via LocaleSettings.baseLocale.languageTag
	static AppLocale get baseLocale {
		return _baseLocale;
	}

	/// Gets supported locales in string format.
	static List<String> get supportedLocalesRaw {
		return AppLocale.values
			.map((locale) => locale.languageTag)
			.toList();
	}

	/// Gets supported locales (as Locale objects) with base locale sorted first.
	static List<Locale> get supportedLocales {
		return FastI18n.convertToLocales(supportedLocalesRaw, _baseLocale.languageTag);
	}
}

// extensions for AppLocale

extension AppLocaleExtensions on AppLocale {
	_Strings get translations {
		switch (this) {
			case AppLocale.de: return _StringsDe._instance;
			case AppLocale.en: return _Strings._instance;
		}
	}

	String get languageTag {
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
	AppLocale locale = _currLocale;

	void setLocale(AppLocale newLocale) {
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
	final AppLocale locale;
	_InheritedLocaleData({required this.locale, required Widget child}) : super(child: child);

	@override
	bool updateShouldNotify(_InheritedLocaleData oldWidget) {
		return oldWidget.locale != locale;
	}
}

// translations

class _StringsDe implements _Strings {
	_StringsDe._(); // no constructor

	static _StringsDe _instance = _StringsDe._();

	@override _StringsMainScreenDe get mainScreen => _StringsMainScreenDe._instance;
	@override Map<String, String> get locales => {
		'en': 'Englisch',
		'de': 'Deutsch',
	};
}

class _StringsMainScreenDe implements _StringsMainScreen {
	_StringsMainScreenDe._(); // no constructor

	static _StringsMainScreenDe _instance = _StringsMainScreenDe._();

	@override String get title => 'Ein deutscher Titel';
	@override String counter({required Object count}) => 'Du hast $count mal gedrückt.';
	@override String get tapMe => 'Drück mich';
}

class _Strings {
	_Strings._(); // no constructor

	static _Strings _instance = _Strings._();

	_StringsMainScreen get mainScreen => _StringsMainScreen._instance;
	Map<String, String> get locales => {
		'en': 'English',
		'de': 'German',
	};
}

class _StringsMainScreen {
	_StringsMainScreen._(); // no constructor

	static _StringsMainScreen _instance = _StringsMainScreen._();

	String get title => 'An English Title';
	String counter({required Object count}) => 'You pressed $count times.';
	String get tapMe => 'Tap me';
}
