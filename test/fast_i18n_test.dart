import 'package:fast_i18n/fast_i18n.dart';
import 'package:test/test.dart';

void main() {
  testSelectLocale();
}

void testSelectLocale() {
  group('selectLocale', () {
    test('match exactly', () {
      expect(FastI18n.selectLocale('en-us', ['en-us', 'de-de']), 'en-us');
    });

    test('match exactly with no country code', () {
      expect(FastI18n.selectLocale('de', ['en', 'de']), 'de');
    });

    test('match exactly but need normalizing', () {
      expect(FastI18n.selectLocale('en_US', ['en-us', 'de-de']), 'en-us');
    });

    test('match first part', () {
      expect(FastI18n.selectLocale('de_DE', ['en', 'de']), 'de');
    });

    test('match last part', () {
      expect(FastI18n.selectLocale('en_US', ['us', 'de']), 'us');
    });

    test('fallback', () {
      expect(FastI18n.selectLocale('fr', ['en', 'de']), '');
    });
  });
}
