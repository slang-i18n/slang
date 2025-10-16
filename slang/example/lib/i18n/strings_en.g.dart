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
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
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

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final TranslationsMainScreenEn mainScreen = TranslationsMainScreenEn._(_root);
	Map<String, String> get locales => {
		'en': 'English',
		'de': 'German',
		'fr-FR': 'French',
	};
}

// Path: mainScreen
class TranslationsMainScreenEn {
	TranslationsMainScreenEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'An English Title'
	String get title => 'An English Title';

	/// en: '(one) {You pressed $n time.} (other) {You pressed $n times.}'
	String counter({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'You pressed ${n} time.',
		other: 'You pressed ${n} times.',
	);

	/// en: 'Tap me'
	String get tapMe => 'Tap me';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
/// Note: We use a HashMap because Dart seems to be unable to compile large switch statements.
Map<String, dynamic>? _map;

extension on Translations {
	dynamic _flatMapFunction(String path) {
		final map = _map ?? _initFlatMap();
		return map[path];
	}

	/// Initializes the flat map and returns it.
	Map<String, dynamic> _initFlatMap() {
		final map = <String, dynamic>{};
		map['mainScreen.title'] = 'An English Title';
		map['mainScreen.counter'] = ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
				one: 'You pressed ${n} time.',
				other: 'You pressed ${n} times.',
			);
		map['mainScreen.tapMe'] = 'Tap me';
		map['locales.en'] = 'English';
		map['locales.de'] = 'German';
		map['locales.fr-FR'] = 'French';

		_map = map;
		return map;
	}
}

