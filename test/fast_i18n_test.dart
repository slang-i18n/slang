import 'package:fast_i18n/fast_i18n.dart';
import 'package:test/test.dart';

void main() {
  testSelectLocale();
}

void testSelectLocale() {
  group('selectLocale', () {
    test('match exactly', () {
      expect(FastI18n.selectLocale('en-us', ['en-us', 'de-de'], ''), 'en-us');
    });

    test('match exactly with no country code', () {
      expect(FastI18n.selectLocale('de', ['en', 'de'], ''), 'de');
    });

    test('match exactly but need normalizing', () {
      expect(FastI18n.selectLocale('en_US', ['en-us', 'de-de'], ''), 'en-us');
    });

    test('match first part', () {
      expect(FastI18n.selectLocale('de_DE', ['en', 'de'], ''), 'de');
    });

    test('prefer first part over second part', () {
      expect(FastI18n.selectLocale('en_DE', ['de', 'en'], ''), 'en');
    });

    test('match last part', () {
      expect(FastI18n.selectLocale('en_US', ['us', 'de'], ''), 'us');
    });

    test('fallback', () {
      expect(FastI18n.selectLocale('fr', ['en', 'de'], 'cz'), 'cz');
    });
  });

  group('convertToLocales', () {
    test('puts the base locale first', () {
      final localesAsStrings = ['en-us', 'ru-RU', 'de-de', 'zh-Hans-CN'];
      final baseLocaleString = 'ru-RU';

      final locales = FastI18n.convertToLocales(localesAsStrings, baseLocaleString);

      expect(locales.length, 4);
      expect(locales[0].toLanguageTag(), 'ru-RU');
      expect(locales[1].toLanguageTag(), 'en-us');
      expect(locales[2].toLanguageTag(), 'de-de');
      expect(locales[3].toLanguageTag(), 'zh-Hans-CN');
    });

    test('when there is no country code present', () {
      final localesAsStrings = ['en', 'ru-RU', 'de'];
      final baseLocaleString = 'de';

      final locales = FastI18n.convertToLocales(localesAsStrings, baseLocaleString);

      expect(locales.length, 3);
      expect(locales[0].toLanguageTag(), 'de');
      expect(locales[1].toLanguageTag(), 'en');
      expect(locales[2].toLanguageTag(), 'ru-RU');
    });

    test("throws Exception if a locale with '-' delimiter doesn't have 2+ non-empty parts", () {
      final localesAsStrings = ['ru-', 'de'];
      final baseLocaleString = 'de';

      expect(
        () => FastI18n.convertToLocales(localesAsStrings, baseLocaleString),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'throws AssertionError if primary language subtag is not present in the provided base locale',
        () {
      final localesAsStrings = ['en-us'];
      final baseLocaleString = '';

      expect(
        () => FastI18n.convertToLocales(localesAsStrings, baseLocaleString),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws AssertionError if primary language subtag is not present in the provided locales',
        () {
      final localesAsStrings = ['en-us', ''];
      final baseLocaleString = 'en-US';

      expect(
        () => FastI18n.convertToLocales(localesAsStrings, baseLocaleString),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
