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
	/// [AppLocaleUtils.buildWithOverrides] is recommended for overriding.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		    types: {
		      'currency': ValueFormatter(() => NumberFormat.currency(symbol: 'USD', locale: 'en')),
		      'date': ValueFormatter(() => DateFormat('dd.MM.yyyy', 'en')),
		    },
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	late final TranslationsMainScreenEn mainScreen = TranslationsMainScreenEn.internal(_root);
	Map<String, String> get locales => TranslationOverrides.map(_root.$meta, 'locales') ?? {
		'en': 'English',
		'de': 'German',
		'fr-FR': 'French',
	};
}

// Path: mainScreen
class TranslationsMainScreenEn {
	TranslationsMainScreenEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => TranslationOverrides.string(_root.$meta, 'mainScreen.title', {}) ?? 'An English Title';
	String counter({required num n}) => TranslationOverrides.plural(_root.$meta, 'mainScreen.counter', {'n': n}) ?? (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'You pressed ${n} time.',
		other: 'You pressed ${n} times.',
	);
	String get tapMe => TranslationOverrides.string(_root.$meta, 'mainScreen.tapMe', {}) ?? 'Tap me';
	String test({required num cool}) => TranslationOverrides.string(_root.$meta, 'mainScreen.test', {'cool': cool}) ?? 'Test ${NumberFormat.currency(symbol: 'EUR', locale: 'en').format(cool)}';
	String test2({required num yay}) => TranslationOverrides.string(_root.$meta, 'mainScreen.test2', {'yay': yay}) ?? 'Test ${_root.$meta.types['currency']!.format(yay)}';
	String today({required DateTime date}) => TranslationOverrides.string(_root.$meta, 'mainScreen.today', {'date': date}) ?? 'Today is ${DateFormat('yyyy-MM-dd', 'en').format(date)}';
	String linked({required num yay}) => TranslationOverrides.string(_root.$meta, 'mainScreen.linked', {'yay': yay}) ?? 'This is a linked string: ${_root.mainScreen.test2(yay: yay)}';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'mainScreen.title': return TranslationOverrides.string(_root.$meta, 'mainScreen.title', {}) ?? 'An English Title';
			case 'mainScreen.counter': return ({required num n}) => TranslationOverrides.plural(_root.$meta, 'mainScreen.counter', {'n': n}) ?? (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
				one: 'You pressed ${n} time.',
				other: 'You pressed ${n} times.',
			);
			case 'mainScreen.tapMe': return TranslationOverrides.string(_root.$meta, 'mainScreen.tapMe', {}) ?? 'Tap me';
			case 'mainScreen.test': return ({required num cool}) => TranslationOverrides.string(_root.$meta, 'mainScreen.test', {'cool': cool}) ?? 'Test ${NumberFormat.currency(symbol: 'EUR', locale: 'en').format(cool)}';
			case 'mainScreen.test2': return ({required num yay}) => TranslationOverrides.string(_root.$meta, 'mainScreen.test2', {'yay': yay}) ?? 'Test ${_root.$meta.types['currency']!.format(yay)}';
			case 'mainScreen.today': return ({required DateTime date}) => TranslationOverrides.string(_root.$meta, 'mainScreen.today', {'date': date}) ?? 'Today is ${DateFormat('yyyy-MM-dd', 'en').format(date)}';
			case 'mainScreen.linked': return ({required num yay}) => TranslationOverrides.string(_root.$meta, 'mainScreen.linked', {'yay': yay}) ?? 'This is a linked string: ${_root.mainScreen.test2(yay: yay)}';
			case 'locales.en': return TranslationOverrides.string(_root.$meta, 'locales.en', {}) ?? 'English';
			case 'locales.de': return TranslationOverrides.string(_root.$meta, 'locales.de', {}) ?? 'German';
			case 'locales.fr-FR': return TranslationOverrides.string(_root.$meta, 'locales.fr-FR', {}) ?? 'French';
			default: return null;
		}
	}
}

