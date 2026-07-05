import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang_flutter/slang_flutter.dart';

class AppLocaleUtils
    extends BaseAppLocaleUtils<FakeAppLocale, FakeTranslations> {
  AppLocaleUtils({required super.baseLocale, required super.locales});
}

void main() {
  final en = FakeAppLocale(languageCode: 'en');
  final enUS = FakeAppLocale(languageCode: 'en', countryCode: 'US');
  final de = FakeAppLocale(languageCode: 'de');

  final utils = AppLocaleUtils(
    baseLocale: en,
    locales: [en, enUS, de],
  );

  test('should resolve a single non-base locale', () {
    expect(
      utils.resolveLocaleList([const Locale('de', 'DE')]),
      de,
    );
  });

  test('should skip locales that only fall back to the base locale', () {
    expect(
      utils.resolveLocaleList([
        const Locale('fr'),
        const Locale('de'),
        const Locale('en'),
      ]),
      de,
    );
  });

  test('should keep the base locale when it is the top preference', () {
    expect(
      utils.resolveLocaleList([
        const Locale('en', 'GB'),
        const Locale('de', 'DE'),
      ]),
      en,
    );
  });

  test('should fall back to the base locale when nothing matches', () {
    expect(
      utils.resolveLocaleList([const Locale('fr')]),
      en,
    );
  });

  test('should return base locale for an empty list', () {
    expect(utils.resolveLocaleList([]), en);
  });
}
