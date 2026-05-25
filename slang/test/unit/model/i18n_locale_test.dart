import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:test/test.dart';

void main() {
  test('Should parse language only', () {
    final locale = I18nLocale.fromString('en');
    expect(locale.language, 'en');
    expect(locale.languageIsWildcard, false);
    expect(locale.script, null);
    expect(locale.country, null);
    expect(locale.languageTag, 'en');
    expect(locale.enumConstant, 'en');
  });

  test('Should parse language and country', () {
    final locale = I18nLocale.fromString('en-US');
    expect(locale.language, 'en');
    expect(locale.languageIsWildcard, false);
    expect(locale.script, null);
    expect(locale.country, 'US');
    expect(locale.languageTag, 'en-US');
    expect(locale.enumConstant, 'enUs');
  });

  test('Should parse language and script', () {
    final locale = I18nLocale.fromString('zh-Hant');
    expect(locale.language, 'zh');
    expect(locale.languageIsWildcard, false);
    expect(locale.script, 'Hant');
    expect(locale.country, null);
    expect(locale.languageTag, 'zh-Hant');
    expect(locale.enumConstant, 'zhHant');
  });

  test('Should parse language, script and country', () {
    final locale = I18nLocale.fromString('zh-Hant-TW');
    expect(locale.language, 'zh');
    expect(locale.languageIsWildcard, false);
    expect(locale.script, 'Hant');
    expect(locale.country, 'TW');
    expect(locale.languageTag, 'zh-Hant-TW');
    expect(locale.enumConstant, 'zhHantTw');
  });

  test('Should fallback to raw string when format is invalid', () {
    final locale = I18nLocale.fromString('en-EN-EN');
    expect(locale.language, 'en-EN-EN');
    expect(locale.languageTag, 'en-EN-EN');
    expect(locale.enumConstant, 'enEnEn');
  });

  test('Should preserve original casing in language tag', () {
    final locale = I18nLocale.fromString('en-En-En');
    expect(locale.languageTag, 'en-En-En');
    expect(locale.enumConstant, 'enEnEn');
  });

  test('Should escape reserved word "is"', () {
    final locale = I18nLocale.fromString('is');
    expect(locale.languageTag, 'is');
    expect(locale.enumConstant, 'icelandic');
  });

  test('Should parse single wildcard with custom locales', () {
    final locale = I18nLocale.fromString('[de,en,fr-FR]');
    expect(locale.language, 'de,en,fr-FR');
    expect(locale.languageIsWildcard, true);
    expect(locale.script, null);
    expect(locale.country, null);
    expect(locale.countryIsWildcard, false);
  });

  test('Should parse language as any wildcard', () {
    final locale = I18nLocale.fromString('[any]-DE');
    expect(locale.language, 'any');
    expect(locale.languageIsWildcard, true);
    expect(locale.script, null);
    expect(locale.country, 'DE');
    expect(locale.countryIsWildcard, false);
  });

  test('Should parse wildcard with custom languages', () {
    final locale = I18nLocale.fromString('[de,en]-DE');
    expect(locale.language, 'de,en');
    expect(locale.languageIsWildcard, true);
    expect(locale.script, null);
    expect(locale.country, 'DE');
    expect(locale.countryIsWildcard, false);
  });

  test('Should parse country as any wildcard', () {
    final locale = I18nLocale.fromString('de-[any]');
    expect(locale.language, 'de');
    expect(locale.languageIsWildcard, false);
    expect(locale.script, null);
    expect(locale.country, 'any');
    expect(locale.countryIsWildcard, true);
  });

  test('Should parse wildcard with custom countries', () {
    final locale = I18nLocale.fromString('de-[DE,US]');
    expect(locale.language, 'de');
    expect(locale.languageIsWildcard, false);
    expect(locale.script, null);
    expect(locale.country, 'DE,US');
    expect(locale.countryIsWildcard, true);
  });
}
