import 'package:fast_i18n/utils.dart';
import 'package:test/test.dart';

void main() {
  testLocaleRegex();
  testNormalize();
}

void testLocaleRegex() {
  group('localeRegex', () {
    RegExp regex = Utils.localeRegex;

    test('strings_en', () {
      RegExpMatch match = regex.firstMatch('strings_en');
      expect(match.group(2), 'strings'); // base name
      expect(match.group(3), 'en'); // language
    });

    test('strings_en_US', () {
      RegExpMatch match = regex.firstMatch('strings_en_US');
      expect(match.group(2), 'strings'); // base name
      expect(match.group(3), 'en');
      expect(match.group(5), 'US');
    });

    test('translations_en-US', () {
      RegExpMatch match = regex.firstMatch('translations_en-US');
      expect(match.group(2), 'translations'); // base name
      expect(match.group(3), 'en');
      expect(match.group(5), 'US');
    });

    test('strings_enUS', () {
      RegExpMatch match = regex.firstMatch('strings_enUS');
      expect(match, null);
    });
  });
}

void testNormalize() {
  group('normalize', () {
    test('en', () {
      expect(Utils.normalize('en'), 'en');
    });

    test('en_US', () {
      expect(Utils.normalize('en_US'), 'en-US');
    });

    test('en-US', () {
      expect(Utils.normalize('en-US'), 'en-US');
    });

    test('enUS', () {
      expect(Utils.normalize('enUS'), 'enUS');
    });
  });
}
