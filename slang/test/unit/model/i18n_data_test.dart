import 'package:slang/builder/model/i18n_data.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/node.dart';
import 'package:test/test.dart';

void main() {
  group('generationComparator', () {
    final root = ObjectNode(
      path: '',
      rawPath: '',
      comment: null,
      modifiers: {},
      entries: {},
      isMap: false,
    );
    test('without base', () {
      List<I18nData> locales = [
        I18nData(
          base: false,
          locale: I18nLocale.fromString('ee'),
          root: root,
          interfaces: [],
        ),
        I18nData(
          base: false,
          locale: I18nLocale.fromString('aa'),
          root: root,
          interfaces: [],
        ),
        I18nData(
          base: false,
          locale: I18nLocale.fromString('ff'),
          root: root,
          interfaces: [],
        ),
        I18nData(
          base: false,
          locale: I18nLocale.fromString('gg'),
          root: root,
          interfaces: [],
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
          interfaces: [],
        ),
        I18nData(
          base: false,
          locale: I18nLocale.fromString('aa'),
          root: root,
          interfaces: [],
        ),
        I18nData(
          base: true,
          locale: I18nLocale.fromString('ff'),
          root: root,
          interfaces: [],
        ),
        I18nData(
          base: false,
          locale: I18nLocale.fromString('gg'),
          root: root,
          interfaces: [],
        ),
      ];
      locales.sort(I18nData.generationComparator);
      expect(locales.map((e) => e.locale.languageTag).toList(),
          ['ff', 'aa', 'ee', 'gg']);
    });
  });
}
