import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang_gpt/util/locales.dart';
import 'package:test/test.dart';

void main() {
  group('getEnglishName', () {
    test('should return exact locale', () {
      final locale = getEnglishName(I18nLocale.fromString('zh-Hans'));
      expect(locale, 'Chinese (Simplified)');
    });

    test('should fallback to language+script', () {
      final locale = getEnglishName(I18nLocale.fromString('zh-Hans-CN'));
      expect(locale, 'Chinese (Simplified)');
    });

    test('should fallback to language', () {
      final locale = getEnglishName(I18nLocale.fromString('de-DE'));
      expect(locale, 'German');
    });
  });
}
