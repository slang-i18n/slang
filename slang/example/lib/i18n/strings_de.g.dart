///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/node.dart';
import 'package:slang/overrides.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsDe extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	/// [AppLocaleUtils.buildWithOverrides] is recommended for overriding.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: $meta = TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		    types: {
		      'currency': ValueFormatter(() => NumberFormat.currency(symbol: 'USD', decimalDigits: 5, locale: 'de')),
		      'date': ValueFormatter(() => DateFormat('dd.MM.yyyy', 'de')),
		    },
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsDe _root = this; // ignore: unused_field

	// Translations
	@override late final _TranslationsMainScreenDe mainScreen = _TranslationsMainScreenDe._(_root);
	@override Map<String, String> get locales => TranslationOverrides.map(_root.$meta, 'locales') ?? {
		'en': 'Englisch',
		'de': 'Deutsch',
		'fr-FR': 'Französisch',
	};
}

// Path: mainScreen
class _TranslationsMainScreenDe extends TranslationsMainScreenEn {
	_TranslationsMainScreenDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => TranslationOverrides.string(_root.$meta, 'mainScreen.title', {}) ?? 'Ein deutscher Titel';
	@override String counter({required num n}) => TranslationOverrides.plural(_root.$meta, 'mainScreen.counter', {'n': n}) ?? (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: 'Du hast einmal gedrückt.',
		other: 'Du hast ${n} mal gedrückt.',
	);
	@override String get tapMe => TranslationOverrides.string(_root.$meta, 'mainScreen.tapMe', {}) ?? 'Drück mich';
	@override String test({required num cool}) => TranslationOverrides.string(_root.$meta, 'mainScreen.test', {'cool': cool}) ?? 'Test ${_root.$meta.types['currency']!.format(cool)}';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'mainScreen.title': return TranslationOverrides.string(_root.$meta, 'mainScreen.title', {}) ?? 'Ein deutscher Titel';
			case 'mainScreen.counter': return ({required num n}) => TranslationOverrides.plural(_root.$meta, 'mainScreen.counter', {'n': n}) ?? (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
				one: 'Du hast einmal gedrückt.',
				other: 'Du hast ${n} mal gedrückt.',
			);
			case 'mainScreen.tapMe': return TranslationOverrides.string(_root.$meta, 'mainScreen.tapMe', {}) ?? 'Drück mich';
			case 'mainScreen.test': return ({required num cool}) => TranslationOverrides.string(_root.$meta, 'mainScreen.test', {'cool': cool}) ?? 'Test ${_root.$meta.types['currency']!.format(cool)}';
			case 'locales.en': return TranslationOverrides.string(_root.$meta, 'locales.en', {}) ?? 'Englisch';
			case 'locales.de': return TranslationOverrides.string(_root.$meta, 'locales.de', {}) ?? 'Deutsch';
			case 'locales.fr-FR': return TranslationOverrides.string(_root.$meta, 'locales.fr-FR', {}) ?? 'Französisch';
			default: return null;
		}
	}
}

