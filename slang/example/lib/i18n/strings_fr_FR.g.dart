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
class TranslationsFrFr extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	/// [AppLocaleUtils.buildWithOverrides] is recommended for overriding.
	TranslationsFrFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: $meta = TranslationMetadata(
		    locale: AppLocale.frFr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr-FR>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsFrFr _root = this; // ignore: unused_field

	// Translations
	@override late final _TranslationsMainScreenFrFr mainScreen = _TranslationsMainScreenFrFr._(_root);
	@override Map<String, String> get locales => TranslationOverrides.map(_root.$meta, 'locales') ?? {
		'en': 'Anglais',
		'de': 'Allemand',
		'fr-FR': 'Français',
	};
}

// Path: mainScreen
class _TranslationsMainScreenFrFr extends TranslationsMainScreenEn {
	_TranslationsMainScreenFrFr._(TranslationsFrFr root) : this._root = root, super.internal(root);

	final TranslationsFrFr _root; // ignore: unused_field

	// Translations
	@override String get title => TranslationOverrides.string(_root.$meta, 'mainScreen.title', {}) ?? 'Le titre français';
	@override String counter({required num n}) => TranslationOverrides.plural(_root.$meta, 'mainScreen.counter', {'n': n}) ?? (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Vous avez appuyé une fois.',
		other: 'Vous avez appuyé ${n} fois.',
	);
	@override String get tapMe => TranslationOverrides.string(_root.$meta, 'mainScreen.tapMe', {}) ?? 'Appuyez-moi';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on TranslationsFrFr {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'mainScreen.title': return TranslationOverrides.string(_root.$meta, 'mainScreen.title', {}) ?? 'Le titre français';
			case 'mainScreen.counter': return ({required num n}) => TranslationOverrides.plural(_root.$meta, 'mainScreen.counter', {'n': n}) ?? (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
				one: 'Vous avez appuyé une fois.',
				other: 'Vous avez appuyé ${n} fois.',
			);
			case 'mainScreen.tapMe': return TranslationOverrides.string(_root.$meta, 'mainScreen.tapMe', {}) ?? 'Appuyez-moi';
			case 'locales.en': return TranslationOverrides.string(_root.$meta, 'locales.en', {}) ?? 'Anglais';
			case 'locales.de': return TranslationOverrides.string(_root.$meta, 'locales.de', {}) ?? 'Allemand';
			case 'locales.fr-FR': return TranslationOverrides.string(_root.$meta, 'locales.fr-FR', {}) ?? 'Français';
			default: return null;
		}
	}
}

