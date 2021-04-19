import 'package:fast_i18n/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('fileWithLocaleRegex', () {
    RegExp regex = Utils.fileWithLocaleRegex;

    test('strings_en', () {
      RegExpMatch? match = regex.firstMatch('strings_en');
      expect(match?.group(2), 'strings'); // base name
      expect(match?.group(3), 'en'); // language
    });

    test('strings_en_US', () {
      RegExpMatch? match = regex.firstMatch('strings_en_US');
      expect(match?.group(2), 'strings'); // base name
      expect(match?.group(3), 'en');
      expect(match?.group(7), 'US');
    });

    test('translations_en-US', () {
      RegExpMatch? match = regex.firstMatch('translations_en-US');
      expect(match?.group(2), 'translations'); // base name
      expect(match?.group(3), 'en');
      expect(match?.group(7), 'US');
    });

    test('strings_zh-Hant-TW', () {
      RegExpMatch? match = regex.firstMatch('strings_zh-Hant-TW');
      expect(match?.group(2), 'strings'); // base name
      expect(match?.group(3), 'zh');
      expect(match?.group(5), 'Hant');
      expect(match?.group(7), 'TW');
    });
  });

  group('baseFileRegex', () {
    RegExp regex = Utils.baseFileRegex;

    test('strings', () {
      RegExpMatch? match = regex.firstMatch('strings');
      expect(match?.group(1), 'strings');
    });

    test('translations', () {
      RegExpMatch? match = regex.firstMatch('translations');
      expect(match?.group(1), 'translations');
    });

    test('strings_', () {
      RegExpMatch? match = regex.firstMatch('strings_');
      expect(match?.group(1), null);
    });
  });

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
