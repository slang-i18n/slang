import 'package:fast_i18n/builder/model/i18n_locale.dart';
import 'package:test/test.dart';

void main() {
  group('languageTag', () {
    test('en', () {
      expect(I18nLocale.fromString('en').languageTag, 'en');
    });

    test('en-US', () {
      expect(I18nLocale.fromString('en-US').languageTag, 'en-US');
    });

    test('zh-Hant', () {
      expect(I18nLocale.fromString('zh-Hant').languageTag, 'zh-Hant');
    });

    test('zh-Hant-TW', () {
      expect(I18nLocale.fromString('zh-Hant-TW').languageTag, 'zh-Hant-TW');
    });
  });

  group('enumConstant', () {
    test('en', () {
      expect(I18nLocale.fromString('en').enumConstant, 'en');
    });

    test('en-EN', () {
      expect(I18nLocale.fromString('en-EN').enumConstant, 'enEn');
    });

    test('en-EN-EN', () {
      expect(I18nLocale.fromString('en-EN-EN').enumConstant, 'enEnEn');
    });

    test('en-En-En', () {
      expect(I18nLocale.fromString('en-En-En').enumConstant, 'enEnEn');
    });
  });
}
