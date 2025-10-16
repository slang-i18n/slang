///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsFrFr implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFrFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.frFr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr-FR>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsFrFr _root = this; // ignore: unused_field

	@override 
	TranslationsFrFr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFrFr(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsMainScreenFrFr mainScreen = _TranslationsMainScreenFrFr._(_root);
	@override Map<String, String> get locales => {
		'en': 'Anglais',
		'de': 'Allemand',
		'fr-FR': 'Français',
	};
}

// Path: mainScreen
class _TranslationsMainScreenFrFr implements TranslationsMainScreenEn {
	_TranslationsMainScreenFrFr._(this._root);

	final TranslationsFrFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Le titre français';
	@override String counter({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Vous avez appuyé une fois.',
		other: 'Vous avez appuyé ${n} fois.',
	);
	@override String get tapMe => 'Appuyez-moi';
}

/// The flat map containing all translations for locale <fr-FR>.
/// Only for edge cases! For simple maps, use the map function of this library.
/// Note: We use a HashMap because Dart seems to be unable to compile large switch statements.
Map<String, dynamic>? _map;

extension on TranslationsFrFr {
	dynamic _flatMapFunction(String path) {
		final map = _map ?? _initFlatMap();
		return map[path];
	}

	/// Initializes the flat map and returns it.
	Map<String, dynamic> _initFlatMap() {
		final map = <String, dynamic>{};
		map['mainScreen.title'] = 'Le titre français';
		map['mainScreen.counter'] = ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
				one: 'Vous avez appuyé une fois.',
				other: 'Vous avez appuyé ${n} fois.',
			);
		map['mainScreen.tapMe'] = 'Appuyez-moi';
		map['locales.en'] = 'Anglais';
		map['locales.de'] = 'Allemand';
		map['locales.fr-FR'] = 'Français';

		_map = map;
		return map;
	}
}

