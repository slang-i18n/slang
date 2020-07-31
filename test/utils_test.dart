import 'package:fast_i18n/utils.dart';
import 'package:test/test.dart';

void main() {
  testSpecialRegex();
  testLocaleRegex();
  testNormalize();
}

void testSpecialRegex() {
  group('specialRegex', () {
    RegExp regex = Utils.specialRegex;

    test('contains space', () {
      expect(regex.hasMatch('hello '), true);
    });

    test('contains dot', () {
      expect(regex.hasMatch('hello.'), true);
    });

    test('contains underscore', () {
      expect(regex.hasMatch('hello_'), true);
    });

    test('contains dash', () {
      expect(regex.hasMatch('hello-'), true);
    });

    test('contains no special character', () {
      expect(regex.hasMatch('hello'), false);
    });
  });
}

void testLocaleRegex() {
  group('localeRegex', () {
    RegExp regex = Utils.localeRegex;

    test('_en', () {
      RegExpMatch match = regex.firstMatch('_en');
      expect(match.group(1), 'en');
    });

    test('_en_US', () {
      RegExpMatch match = regex.firstMatch('_en_US');
      expect(match.group(1), 'en');
      expect(match.group(3), 'US');
    });

    test('_en-US', () {
      RegExpMatch match = regex.firstMatch('_en-US');
      expect(match.group(1), 'en');
      expect(match.group(3), 'US');
    });

    test('_enUS', () {
      RegExpMatch match = regex.firstMatch('_enUS');
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
      expect(Utils.normalize('en_US'), 'en-us');
    });

    test('en-US', () {
      expect(Utils.normalize('en-US'), 'en-us');
    });

    test('enUS', () {
      expect(Utils.normalize('enUS'), 'enus');
    });
  });
}
