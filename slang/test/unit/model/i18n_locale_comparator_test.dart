import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:test/test.dart';

List<String> _sort(List<String> locales, String baseLocale) {
  final base = I18nLocale.fromString(baseLocale);
  return (locales.map(I18nLocale.fromString).toList()
        ..sort((a, b) => I18nLocale.generationComparator(a, b, base)))
      .map((e) => e.languageTag)
      .toList();
}

void main() {
  group('generationComparator', () {
    test('without base', () {
      expect(
        _sort(['ee', 'aa', 'ff', 'gg'], 'zz'),
        ['aa', 'ee', 'ff', 'gg'],
      );
    });

    test('with base', () {
      expect(
        _sort(['ee', 'aa', 'ff', 'gg'], 'ff'),
        ['ff', 'aa', 'ee', 'gg'],
      );
    });

    test('language-only locales before the rest', () {
      expect(
        _sort(['de-DE', 'ee', 'aa-AA', 'aa', 'ff'], 'zz'),
        ['aa', 'ee', 'ff', 'aa-AA', 'de-DE'],
      );
    });

    test('base first, then language-only, then the rest', () {
      expect(
        _sort(['de-DE', 'ee', 'aa-AA', 'ff', 'aa'], 'ff'),
        ['ff', 'aa', 'ee', 'aa-AA', 'de-DE'],
      );
    });
  });
}
