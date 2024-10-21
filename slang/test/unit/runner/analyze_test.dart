import 'package:slang/src/builder/builder/translation_model_list_builder.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:slang/src/runner/analyze.dart';
import 'package:test/test.dart';

import '../../util/mocks/fake_file.dart';

void main() {
  group('loadSourceCode', () {
    test('join multiple files', () {
      final files = [
        FakeFile('A'),
        FakeFile('B'),
        FakeFile('C'),
      ];

      final result = loadSourceCode(files);

      expect(result, 'ABC');
    });

    test('should ignore spaces', () {
      final files = [
        FakeFile('A\nB C\tD'),
        FakeFile('E\r\nF  G'),
        FakeFile('H;'),
      ];

      final result = loadSourceCode(files);

      expect(result, 'ABCDEFGH;');
    });

    test('should ignore inline comments', () {
      final files = [
        FakeFile('A // B\nC'),
        FakeFile('D /* E */ F'),
        FakeFile('G'),
      ];

      final result = loadSourceCode(files);

      expect(result, 'ACDFG');
    });

    test('should ignore block comments', () {
      final files = [
        FakeFile('A /* B\nC */ D'),
        FakeFile('E // F'),
        FakeFile('G //'),
      ];

      final result = loadSourceCode(files);

      expect(result, 'ADEG');
    });
  });

  group('getUnusedTranslations', () {
    test('Should find unused but translations', () {
      final result = _getUnusedTranslations({
        'en': {
          'a': 'A',
        },
        'de': {
          'a': 'A',
          'b': 'B',
        },
      });

      expect(result[I18nLocale(language: 'de')], {'b': 'B'});
    });

    test('Should ignore unused but linked translations', () {
      final result = _getUnusedTranslations({
        'en': {
          'a': 'A',
        },
        'de': {
          'a': 'A @:b',
          'b': 'B',
        },
      });

      expect(result[I18nLocale(language: 'de')], isEmpty);
    });
  });
}

Map<I18nLocale, Map<String, dynamic>> _getUnusedTranslations(
  Map<String, Map<String, dynamic>> translations,
) {
  final map = TranslationMap();
  for (final entry in translations.entries) {
    map.addTranslations(
      locale: I18nLocale(language: entry.key),
      translations: entry.value,
    );
  }

  return getUnusedTranslations(
    rawConfig: RawConfig.defaultConfig,
    translations: TranslationModelListBuilder.build(
      RawConfig.defaultConfig,
      map,
    ),
    full: false,
  );
}
