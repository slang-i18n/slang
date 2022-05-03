
/*
 * Generated file. Do not edit.
 *
 * Locales: 2
 * Strings: 12 (6.0 per locale)
 *
 * Built on 2022-05-03 at 01:10 UTC
 */

// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:fast_i18n_flutter/fast_i18n_flutter.dart';

const AppLocale _baseLocale = AppLocale.en;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale {
	en,	// 'en' (base locale, fallback)
	de,	// 'de'
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
_StringsEn get t => LocaleSettings.instance.currentTranslations;

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

	static _StringsEn of(BuildContext context) => InheritedLocaleData.of<AppLocale, _StringsEn>(context).translations;
}

class LocaleSettings extends BaseLocaleSettings<AppLocale, _StringsEn> {
	LocaleSettings._() : super(
		locales: AppLocale.values,
		baseLocale: _baseLocale,
		mapper: _mapper,
		translationMap: <AppLocale, _StringsEn>{
			AppLocale.en: _StringsEn.build(),
			AppLocale.de: _StringsDe.build(),
		},
		utils: AppLocaleUtils.instance,
	);

	static final instance = LocaleSettings._();
}

class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale> {
	AppLocaleUtils._() : super(mapper: _mapper, baseLocale: _baseLocale);

	static final instance = AppLocaleUtils._();

	// static aliases
	static AppLocale parse(String rawLocale) => instance.parseRawLocale(rawLocale);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
}

// context enums

// interfaces generated as mixins

// extensions for AppLocale

extension AppLocaleExtensions on AppLocale {

	/// Gets the translation instance managed by this library.
	/// [TranslationProvider] is using this instance.
	/// The plural resolvers are set via [LocaleSettings].
	_StringsEn get translations {
		return LocaleSettings.instance.translationMap[this]!;
	}

	/// Gets a new translation instance.
	/// [LocaleSettings] has no effect here.
	/// Suitable for dependency injection and unit tests.
	///
	/// Usage:
	/// final t = AppLocale.en.build(); // build
	/// String a = t.my.path; // access
	_StringsEn build({PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) {
		switch (this) {
			case AppLocale.en: return _StringsEn.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);
			case AppLocale.de: return _StringsDe.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);
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

// pluralization resolvers

typedef PluralResolver = String Function(num n, {String? zero, String? one, String? two, String? few, String? many, String? other});

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

final _mapper = AppLocaleIdMapper<AppLocale>(
	localeMap: {
		const AppLocaleId(languageCode: 'en'): AppLocale.en,
		const AppLocaleId(languageCode: 'de'): AppLocale.de,
	}
);

// translations

// Path: <root>
class _StringsEn implements BaseTranslations {

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsEn.build({PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: _cardinalResolver = cardinalResolver,
		  _ordinalResolver = ordinalResolver;

	/// The same as [build] but calling on an instance
	@override _StringsEn copyWith({PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) {
		return _StringsEn.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);
	}

	/// Access flat map
	dynamic operator[](String key) => _flatMap[key];

	// Internal flat map initialized lazily
	late final Map<String, dynamic> _flatMap = _buildFlatMap();

	final PluralResolver? _cardinalResolver; // ignore: unused_field
	final PluralResolver? _ordinalResolver; // ignore: unused_field

	late final _StringsEn _root = this; // ignore: unused_field

	// Translations
	late final _StringsMainScreenEn mainScreen = _StringsMainScreenEn._(_root);
	Map<String, String> get locales => {
		'en': 'English',
		'de': 'German',
	};
}

// Path: mainScreen
class _StringsMainScreenEn {
	_StringsMainScreenEn._(this._root);

	final _StringsEn _root; // ignore: unused_field

	// Translations
	String get title => 'An English Title';
	String counter({required num count}) => (_root._cardinalResolver ?? _pluralCardinalEn)(count,
		one: 'You pressed $count time.',
		other: 'You pressed $count times.',
	);
	String get tapMe => 'Tap me';
}

// Path: <root>
class _StringsDe implements _StringsEn {

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsDe.build({PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: _cardinalResolver = cardinalResolver,
		  _ordinalResolver = ordinalResolver;

	/// The same as [build] but calling on an instance
	@override _StringsDe copyWith({PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) {
		return _StringsDe.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);
	}

	/// Access flat map
	@override dynamic operator[](String key) => _flatMap[key];

	// Internal flat map initialized lazily
	@override late final Map<String, dynamic> _flatMap = _buildFlatMap();

	@override final PluralResolver? _cardinalResolver; // ignore: unused_field
	@override final PluralResolver? _ordinalResolver; // ignore: unused_field

	@override late final _StringsDe _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsMainScreenDe mainScreen = _StringsMainScreenDe._(_root);
	@override Map<String, String> get locales => {
		'en': 'Englisch',
		'de': 'Deutsch',
	};
}

// Path: mainScreen
class _StringsMainScreenDe implements _StringsMainScreenEn {
	_StringsMainScreenDe._(this._root);

	@override final _StringsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ein deutscher Titel';
	@override String counter({required num count}) => (_root._cardinalResolver ?? _pluralCardinalDe)(count,
		one: 'Du hast einmal gedrückt.',
		other: 'Du hast $count mal gedrückt.',
	);
	@override String get tapMe => 'Drück mich';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on _StringsEn {
	Map<String, dynamic> _buildFlatMap() {
		return <String, dynamic>{
			'mainScreen.title': 'An English Title',
			'mainScreen.counter': ({required num count}) => (_root._cardinalResolver ?? _pluralCardinalEn)(count,
				one: 'You pressed $count time.',
				other: 'You pressed $count times.',
			),
			'mainScreen.tapMe': 'Tap me',
			'locales.en': 'English',
			'locales.de': 'German',
		};
	}
}

extension on _StringsDe {
	Map<String, dynamic> _buildFlatMap() {
		return <String, dynamic>{
			'mainScreen.title': 'Ein deutscher Titel',
			'mainScreen.counter': ({required num count}) => (_root._cardinalResolver ?? _pluralCardinalDe)(count,
				one: 'Du hast einmal gedrückt.',
				other: 'Du hast $count mal gedrückt.',
			),
			'mainScreen.tapMe': 'Drück mich',
			'locales.en': 'Englisch',
			'locales.de': 'Deutsch',
		};
	}
}
