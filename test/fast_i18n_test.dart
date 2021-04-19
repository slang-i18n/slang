import 'package:fast_i18n/fast_i18n.dart';
import 'package:test/test.dart';

void main() {
  group('selectLocale', () {
    test('match exactly', () {
      expect(FastI18n.selectLocale('en-us', ['en-us', 'de-de'], ''), 'en-us');
    });

    test('match exactly with no country code', () {
      expect(FastI18n.selectLocale('de', ['en', 'de'], ''), 'de');
    });

    test('match exactly but need normalizing', () {
      expect(FastI18n.selectLocale('en_US', ['en-US', 'de-DE'], ''), 'en-US');
    });

    test('match first part (language) of candidate', () {
      expect(FastI18n.selectLocale('de_DE', ['en', 'de'], ''), 'de');
    });

    test('match first part (language) of supported', () {
      expect(FastI18n.selectLocale('de', ['en-US', 'de-DE'], ''), 'de-DE');
    });

    test('prefer first part (language) over second part (country)', () {
      expect(FastI18n.selectLocale('en_DE', ['de', 'en'], ''), 'en');
    });

    test('fallback', () {
      expect(FastI18n.selectLocale('fr', ['en', 'de'], 'cz'), 'cz');
    });
  });
}
