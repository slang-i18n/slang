
/*
 * Generated file. Do not edit.
 *
 * Locales: 2
 * Strings: 18 (9.0 per locale)
 *
 * Built on 2020-07-26 at 00:00 UTC
 */

import 'package:flutter/widgets.dart';

const AppLocale _baseLocale = AppLocale.en;
AppLocale _currLocale = _baseLocale;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale {
	en, // 'en' (base locale, fallback)
	de, // 'de'
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
_StringsEn _t = _currLocale.translations;
_StringsEn get t => _t;

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
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class Translations {
	Translations._(); // no constructor

	static _StringsEn of(BuildContext context) {
		final inheritedWidget = context.dependOnInheritedWidgetOfExactType<_InheritedLocaleData>();
		if (inheritedWidget == null) {
			throw 'Please wrap your app with "TranslationProvider".';
		}
		return inheritedWidget.translations;
	}
}

class LocaleSettings {
	LocaleSettings._(); // no constructor

	/// Uses locale of the device, fallbacks to base locale.
	/// Returns the locale which has been set.
	/// Hint for pre 4.x.x developers: You can access the raw string via LocaleSettings.useDeviceLocale().languageTag
	static AppLocale useDeviceLocale() {
		final String? deviceLocale = WidgetsBinding.instance?.window.locale.toLanguageTag();
		if (deviceLocale != null) {
			return setLocaleRaw(deviceLocale);
		} else {
			return setLocale(_baseLocale);
		}
	}

	/// Sets locale
	/// Returns the locale which has been set.
	static AppLocale setLocale(AppLocale locale) {
		_currLocale = locale;
		_t = _currLocale.translations;

		if (WidgetsBinding.instance != null) {
			// force rebuild if TranslationProvider is used
			_translationProviderKey.currentState?.setLocale(_currLocale);
		}

		return _currLocale;
	}

	/// Sets locale using string tag (e.g. en_US, de-DE, fr)
	/// Fallbacks to base locale.
	/// Returns the locale which has been set.
	static AppLocale setLocaleRaw(String localeRaw) {
		final selected = _selectLocale(localeRaw);
		return setLocale(selected ?? _baseLocale);
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
		return AppLocale.values
			.map((locale) => locale.flutterLocale)
			.toList();
	}

	/// Sets plural resolvers.
	/// See https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html
	/// See https://github.com/Tienisto/flutter-fast-i18n/blob/master/lib/src/model/pluralization_resolvers.dart
	/// Only language part matters, script and country parts are ignored
	/// Rendered Resolvers: ['en', 'de']
	static void setPluralResolver({required String language, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) {
		if (cardinalResolver != null) _pluralResolversCardinal[language] = cardinalResolver;
		if (ordinalResolver != null) _pluralResolversOrdinal[language] = ordinalResolver;
	}

}

// context enums

// interfaces generated as mixins

mixin PageData {
	String get title;
	String? get content => null;
}

// extensions for AppLocale

extension AppLocaleExtensions on AppLocale {
	_StringsEn get translations {
		switch (this) {
			case AppLocale.en: return _StringsEn._instance;
			case AppLocale.de: return _StringsDe._instance;
		}
	}

	String get languageTag {
		switch (this) {
			case AppLocale.en: return 'en';
			case AppLocale.de: return 'de';
		}
	}

	Locale get flutterLocale {
		switch (this) {
			case AppLocale.en: return const Locale.fromSubtags(languageCode: 'en');
			case AppLocale.de: return const Locale.fromSubtags(languageCode: 'de');
		}
	}
}

extension StringAppLocaleExtensions on String {
	AppLocale? toAppLocale() {
		switch (this) {
			case 'en': return AppLocale.en;
			case 'de': return AppLocale.de;
			default: return null;
		}
	}
}

// wrappers

GlobalKey<_TranslationProviderState> _translationProviderKey = GlobalKey<_TranslationProviderState>();

class TranslationProvider extends StatefulWidget {
	TranslationProvider({required this.child}) : super(key: _translationProviderKey);

	final Widget child;

	@override
	_TranslationProviderState createState() => _TranslationProviderState();

	static _InheritedLocaleData of(BuildContext context) {
		final inheritedWidget = context.dependOnInheritedWidgetOfExactType<_InheritedLocaleData>();
		if (inheritedWidget == null) {
			throw 'Please wrap your app with "TranslationProvider".';
		}
		return inheritedWidget;
	}
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
	Locale get flutterLocale => locale.flutterLocale; // shortcut
	final _StringsEn translations; // store translations to avoid switch call

	_InheritedLocaleData({required this.locale, required Widget child})
		: translations = locale.translations, super(child: child);

	@override
	bool updateShouldNotify(_InheritedLocaleData oldWidget) {
		return oldWidget.locale != locale;
	}
}

// pluralization resolvers

// map: language -> resolver
typedef PluralResolver = String Function(num n, {String? zero, String? one, String? two, String? few, String? many, String? other});
Map<String, PluralResolver> _pluralResolversCardinal = {};
Map<String, PluralResolver> _pluralResolversOrdinal = {};

// prepared by fast_i18n

String _pluralCardinalEn(num n, {String? zero, String? one, String? two, String? few, String? many, String? other}) {
	if (n == 0) {
		return zero ?? other!;
	} else if (n == 1) {
		return one ?? other!;
	}
	return other!;
}

String _pluralCardinalDe(num n, {String? zero, String? one, String? two, String? few, String? many, String? other}) {
	if (n == 0) {
		return zero ?? other!;
	} else if (n == 1) {
		return one ?? other!;
	}
	return other!;
}

// helpers

final _localeRegex = RegExp(r'^([a-z]{2,8})?([_-]([A-Za-z]{4}))?([_-]?([A-Z]{2}|[0-9]{3}))?$');
AppLocale? _selectLocale(String localeRaw) {
	final match = _localeRegex.firstMatch(localeRaw);
	AppLocale? selected;
	if (match != null) {
		final language = match.group(1);
		final country = match.group(5);

		// match exactly
		selected = AppLocale.values
			.cast<AppLocale?>()
			.firstWhere((supported) => supported?.languageTag == localeRaw.replaceAll('_', '-'), orElse: () => null);

		if (selected == null && language != null) {
			// match language
			selected = AppLocale.values
				.cast<AppLocale?>()
				.firstWhere((supported) => supported?.languageTag.startsWith(language) == true, orElse: () => null);
		}

		if (selected == null && country != null) {
			// match country
			selected = AppLocale.values
				.cast<AppLocale?>()
				.firstWhere((supported) => supported?.languageTag.contains(country) == true, orElse: () => null);
		}
	}
	return selected;
}

// translations

class _StringsEn {
	_StringsEn._(); // no constructor

	static final _StringsEn _instance = _StringsEn._();

	_StringsOnboardingEn get onboarding => _StringsOnboardingEn._instance;
	String bye({required Object firstName}) => 'Bye $firstName';
	_StringsGroupEn get group => _StringsGroupEn._instance;
	String a({required Object name, required num count, required Object firstName}) => 'Hello ${AppLocale.en.translations.group.users(name: name, count: count, firstName: firstName)}';

	/// A flat map containing all translations.
	dynamic operator[](String key) {
		return _translationMap[AppLocale.en]![key];
	}
}

class _StringsOnboardingEn {
	_StringsOnboardingEn._(); // no constructor

	static final _StringsOnboardingEn _instance = _StringsOnboardingEn._();

	String welcome({required Object name}) => 'Welcome $name';
	List<PageData> get pages => [
		_StringsOnboarding0i0En._instance,
		_StringsOnboarding0i1En._instance,
	];
}

class _StringsGroupEn {
	_StringsGroupEn._(); // no constructor

	static final _StringsGroupEn _instance = _StringsGroupEn._();

	String users({required num count, required Object name, required Object firstName}) => (_pluralResolversCardinal['en'] ?? _pluralCardinalEn)(count,
		zero: 'No Users and ${AppLocale.en.translations.onboarding.welcome(name: name)}',
		one: 'One User',
		other: '$count Users and ${AppLocale.en.translations.bye(firstName: firstName)}',
	);
}

class _StringsOnboarding0i0En with PageData {
	_StringsOnboarding0i0En._(); // no constructor

	static final _StringsOnboarding0i0En _instance = _StringsOnboarding0i0En._();

	@override String get title => 'First Page';
	@override String get content => 'First Page Content';
}

class _StringsOnboarding0i1En with PageData {
	_StringsOnboarding0i1En._(); // no constructor

	static final _StringsOnboarding0i1En _instance = _StringsOnboarding0i1En._();

	@override String get title => 'Second Page';
}

class _StringsDe implements _StringsEn {
	_StringsDe._(); // no constructor

	static final _StringsDe _instance = _StringsDe._();

	@override _StringsOnboardingDe get onboarding => _StringsOnboardingDe._instance;
	@override String bye({required Object firstName}) => 'Tschüss $firstName';
	@override _StringsGroupDe get group => _StringsGroupDe._instance;
	@override String a({required Object name, required num count, required Object firstName}) => 'Hallo ${AppLocale.de.translations.group.users(name: name, count: count, firstName: firstName)}';

	/// A flat map containing all translations.
	@override
	dynamic operator[](String key) {
		return _translationMap[AppLocale.de]![key];
	}
}

class _StringsOnboardingDe implements _StringsOnboardingEn {
	_StringsOnboardingDe._(); // no constructor

	static final _StringsOnboardingDe _instance = _StringsOnboardingDe._();

	@override String welcome({required Object name}) => 'Willkommen $name';
	@override List<PageData> get pages => [
		_StringsOnboarding0i0De._instance,
		_StringsOnboarding0i1De._instance,
	];
}

class _StringsGroupDe implements _StringsGroupEn {
	_StringsGroupDe._(); // no constructor

	static final _StringsGroupDe _instance = _StringsGroupDe._();

	@override String users({required num count, required Object name, required Object firstName}) => (_pluralResolversCardinal['de'] ?? _pluralCardinalDe)(count,
		zero: 'Keine Nutzer und ${AppLocale.de.translations.onboarding.welcome(name: name)}',
		one: 'Ein Nutzer',
		other: '$count Nutzer und ${AppLocale.de.translations.bye(firstName: firstName)}',
	);
}

class _StringsOnboarding0i0De with PageData implements _StringsOnboarding0i0En {
	_StringsOnboarding0i0De._(); // no constructor

	static final _StringsOnboarding0i0De _instance = _StringsOnboarding0i0De._();

	@override String get title => 'Erste Seite';
	@override String get content => 'Erster Seiteninhalt';
}

class _StringsOnboarding0i1De with PageData implements _StringsOnboarding0i1En {
	_StringsOnboarding0i1De._(); // no constructor

	static final _StringsOnboarding0i1De _instance = _StringsOnboarding0i1De._();

	@override String get title => 'Zweite Seite';
}

/// A flat map containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
late Map<AppLocale, Map<String, dynamic>> _translationMap = {
	AppLocale.en: {
		'onboarding.welcome': ({required Object name}) => 'Welcome $name',
		'onboarding.pages.0.title': 'First Page',
		'onboarding.pages.0.content': 'First Page Content',
		'onboarding.pages.1.title': 'Second Page',
		'bye': ({required Object firstName}) => 'Bye $firstName',
		'group.users': ({required num count, required Object name, required Object firstName}) => (_pluralResolversCardinal['en'] ?? _pluralCardinalEn)(count,
			zero: 'No Users and ${AppLocale.en.translations.onboarding.welcome(name: name)}',
			one: 'One User',
			other: '$count Users and ${AppLocale.en.translations.bye(firstName: firstName)}',
		),
		'a': ({required Object name, required num count, required Object firstName}) => 'Hello ${AppLocale.en.translations.group.users(name: name, count: count, firstName: firstName)}',
	},
	AppLocale.de: {
		'onboarding.welcome': ({required Object name}) => 'Willkommen $name',
		'onboarding.pages.0.title': 'Erste Seite',
		'onboarding.pages.0.content': 'Erster Seiteninhalt',
		'onboarding.pages.1.title': 'Zweite Seite',
		'bye': ({required Object firstName}) => 'Tschüss $firstName',
		'group.users': ({required num count, required Object name, required Object firstName}) => (_pluralResolversCardinal['de'] ?? _pluralCardinalDe)(count,
			zero: 'Keine Nutzer und ${AppLocale.de.translations.onboarding.welcome(name: name)}',
			one: 'Ein Nutzer',
			other: '$count Nutzer und ${AppLocale.de.translations.bye(firstName: firstName)}',
		),
		'a': ({required Object name, required num count, required Object firstName}) => 'Hallo ${AppLocale.de.translations.group.users(name: name, count: count, firstName: firstName)}',
	},
};
