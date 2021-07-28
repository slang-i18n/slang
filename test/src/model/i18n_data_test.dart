import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:test/test.dart';

void main() {
  group('generationComparator', () {
    final root = ObjectNode({}, ObjectNodeType.classType, null);
    test('without base', () {
      List<I18nData> locales = [
        I18nData(
          base: false,
          locale: I18nLocale.fromString('ee'),
          root: root,
          hasCardinal: false,
          hasOrdinal: false,
        ),
        I18nData(
          base: false,
          locale: I18nLocale.fromString('aa'),
          root: root,
          hasCardinal: false,
          hasOrdinal: false,
        ),
        I18nData(
          base: false,
          locale: I18nLocale.fromString('ff'),
          root: root,
          hasCardinal: false,
          hasOrdinal: false,
        ),
        I18nData(
          base: false,
          locale: I18nLocale.fromString('gg'),
          root: root,
          hasCardinal: false,
          hasOrdinal: false,
        ),
      ];
      locales.sort(I18nData.generationComparator);
      expect(locales.map((e) => e.locale.languageTag).toList(),
          ['aa', 'ee', 'ff', 'gg']);
    });

    test('with base', () {
      List<I18nData> locales = [
        I18nData(
          base: false,
          locale: I18nLocale.fromString('ee'),
          root: root,
          hasCardinal: false,
          hasOrdinal: false,
        ),
        I18nData(
          base: false,
          locale: I18nLocale.fromString('aa'),
          root: root,
          hasCardinal: false,
          hasOrdinal: false,
        ),
        I18nData(
          base: true,
          locale: I18nLocale.fromString('ff'),
          root: root,
          hasCardinal: false,
          hasOrdinal: false,
        ),
        I18nData(
          base: false,
          locale: I18nLocale.fromString('gg'),
          root: root,
          hasCardinal: false,
          hasOrdinal: false,
        ),
      ];
      locales.sort(I18nData.generationComparator);
      expect(locales.map((e) => e.locale.languageTag).toList(),
          ['ff', 'aa', 'ee', 'gg']);
    });
  });
}
