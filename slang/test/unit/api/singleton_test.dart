import 'package:slang/src/api/locale.dart';
import 'package:slang/src/api/singleton.dart';
import 'package:test/test.dart';

class AppLocaleUtils
    extends BaseAppLocaleUtils<FakeAppLocale, FakeTranslations> {
  AppLocaleUtils({required super.baseLocale, required super.locales});
}

void main() {
  final nlBE = FakeAppLocale(languageCode: 'nl', countryCode: 'BE');
  final deAu = FakeAppLocale(languageCode: 'de', countryCode: 'AU');
  final deDe = FakeAppLocale(languageCode: 'de', countryCode: 'DE');
  final deCh = FakeAppLocale(languageCode: 'de', countryCode: 'CH');
  final esEs = FakeAppLocale(languageCode: 'es', countryCode: 'ES');
  final zhCN = FakeAppLocale(languageCode: 'zh', countryCode: 'CN');
  final zhHK = FakeAppLocale(languageCode: 'zh', countryCode: 'HK');
  final zhTW = FakeAppLocale(languageCode: 'zh', countryCode: 'TW');

  group('parseLocaleParts', () {
    test('should match exactly', () {
      final utils = AppLocaleUtils(
        baseLocale: esEs,
        locales: [
          esEs,
          deAu,
          deDe,
          deCh,
        ],
      );

      expect(
        utils.parseLocaleParts(languageCode: 'de', countryCode: 'DE'),
        deDe,
      );
    });

    test('should match language', () {
      final utils = AppLocaleUtils(
        baseLocale: esEs,
        locales: [
          nlBE,
          esEs,
          deDe,
          zhCN,
          zhHK,
        ],
      );

      expect(
        utils.parseLocaleParts(languageCode: 'de', countryCode: 'CH'),
        deDe,
      );
    });

    test('should match first language when there is no country code', () {
      final utils = AppLocaleUtils(
        baseLocale: esEs,
        locales: [
          esEs,
          zhCN,
          zhTW,
        ],
      );

      expect(
        utils.parseLocaleParts(languageCode: 'zh', scriptCode: 'Hans'),
        zhCN,
      );
    });

    test('should match first language when there is a country code', () {
      final utils = AppLocaleUtils(
        baseLocale: esEs,
        locales: [
          deDe,
          deAu,
        ],
      );

      expect(
        utils.parseLocaleParts(languageCode: 'de', countryCode: 'CH'),
        deDe,
      );
    });

    test('should match country', () {
      final utils = AppLocaleUtils(
        baseLocale: deDe,
        locales: [
          deDe,
          nlBE,
          esEs,
          zhCN,
        ],
      );

      expect(
        utils.parseLocaleParts(languageCode: 'fr', countryCode: 'BE'),
        nlBE,
      );
    });

    test('should match language and country', () {
      final utils = AppLocaleUtils(
        baseLocale: deDe,
        locales: [
          deDe,
          nlBE,
          zhCN,
          zhTW,
          zhHK,
        ],
      );

      expect(
        utils.parseLocaleParts(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
        zhTW,
      );
    });

    test('should fallback to base locale', () {
      final utils = AppLocaleUtils(
        baseLocale: esEs,
        locales: [
          esEs,
          deDe,
          nlBE,
          zhCN,
        ],
      );

      expect(
        utils.parseLocaleParts(languageCode: 'fr', countryCode: 'FR'),
        esEs,
      );
    });
  });

  group('parse', () {
    final enGB = FakeAppLocale(languageCode: 'en', countryCode: 'GB');
    final enIN = FakeAppLocale(languageCode: 'en', countryCode: 'IN');
    final enUS = FakeAppLocale(languageCode: 'en', countryCode: 'US');
    final zhMY = FakeAppLocale(languageCode: 'zh', countryCode: 'MY');
    final zhHantTW = FakeAppLocale(
      languageCode: 'zh',
      scriptCode: 'Hant',
      countryCode: 'TW',
    );

    final utils = AppLocaleUtils(
      baseLocale: zhMY,
      locales: [
        enGB,
        enIN,
        enUS,
        zhCN,
        zhMY,
        zhHantTW,
      ],
    );

    test('should honor country code with dash separator', () {
      expect(utils.parse('en-US'), enUS);
      expect(utils.parse('en-IN'), enIN);
    });

    test('should honor country code with underscore separator', () {
      expect(utils.parse('en_US'), enUS);
    });

    test('should honor script and country code', () {
      expect(utils.parse('zh-Hant-TW'), zhHantTW);
    });

    test('should match language only when no country code', () {
      expect(utils.parse('en'), enGB);
    });

    test('should fallback to base locale when no match', () {
      expect(utils.parse('fr-FR'), zhMY);
    });
  });
}
