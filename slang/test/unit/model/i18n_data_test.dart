import 'package:slang/src/builder/model/i18n_data.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/node.dart';
import 'package:test/test.dart';

I18nData _i18n(String locale, [bool base = false]) {
  return I18nData(
    base: base,
    locale: I18nLocale.fromString(locale),
    root: ObjectNode(
      path: '',
      rawPath: '',
      comment: null,
      modifiers: {},
      entries: {},
      isMap: false,
    ),
    contexts: [],
    interfaces: [],
    types: {},
  );
}

void main() {
  group('generationComparator', () {
    test('without base', () {
      List<I18nData> locales = [
        _i18n('ee'),
        _i18n('aa'),
        _i18n('ff'),
        _i18n('gg'),
      ];
      locales.sort(I18nData.generationComparator);
      expect(locales.map((e) => e.locale.languageTag).toList(),
          ['aa', 'ee', 'ff', 'gg']);
    });

    test('with base', () {
      List<I18nData> locales = [
        _i18n('ee'),
        _i18n('aa'),
        _i18n('ff', true),
        _i18n('gg'),
      ];
      locales.sort(I18nData.generationComparator);
      expect(locales.map((e) => e.locale.languageTag).toList(),
          ['ff', 'aa', 'ee', 'gg']);
    });
  });
}
