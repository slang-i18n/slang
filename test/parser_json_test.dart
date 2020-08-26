import 'package:fast_i18n/src/model.dart';
import 'package:fast_i18n/src/parser_json.dart';
import 'package:test/test.dart';

void main() {
  testParseConfig();
}

void testParseConfig() {
  group('parseConfig', () {
    test('empty config', () {
      I18nConfig config = parseConfig('{}');
      expect(config.baseLocale, '');
      expect(config.maps, []);
    });

    test('base locale only', () {
      I18nConfig config = parseConfig('{ "baseLocale": "en" }');
      expect(config.baseLocale, 'en');
      expect(config.maps, []);
    });

    test('maps only', () {
      I18nConfig config = parseConfig('{ "maps": [ "a", "b", "c.d" ] }');
      expect(config.baseLocale, '');
      expect(config.maps, ['a', 'b', 'c.d']);
    });

    test('full config', () {
      I18nConfig config =
          parseConfig('{ "baseLocale": "de", "maps": [ "a", "b.c" ] }');
      expect(config.baseLocale, 'de');
      expect(config.maps, ['a', 'b.c']);
    });

    test('unknown key', () {
      I18nConfig config = parseConfig('{ "blabla": "en" }');
      expect(config.baseLocale, '');
      expect(config.maps, []);
    });

    test('unknown key with base locale', () {
      I18nConfig config = parseConfig('{ "blabla": "en", "baseLocale": "fr" }');
      expect(config.baseLocale, 'fr');
      expect(config.maps, []);
    });
  });
}
