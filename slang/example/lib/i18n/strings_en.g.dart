///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta,})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	late final TranslationsMainScreenEn mainScreen = TranslationsMainScreenEn._(_root);
	Map<String, String> get locales => {
		'en': 'English',
		'de': 'German',
		'fr-FR': 'French',
	};

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);
}

// Path: mainScreen
class TranslationsMainScreenEn {
	TranslationsMainScreenEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'An English Title';
	String counter({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'You pressed ${n} time.',
		other: 'You pressed ${n} times.',
	);
	String get tapMe => 'Tap me';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'mainScreen.title': return 'An English Title';
			case 'mainScreen.counter': return ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
				one: 'You pressed ${n} time.',
				other: 'You pressed ${n} times.',
			);
			case 'mainScreen.tapMe': return 'Tap me';
			case 'locales.en': return 'English';
			case 'locales.de': return 'German';
			case 'locales.fr-FR': return 'French';
			default: return null;
		}
	}
}

