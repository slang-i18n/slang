import 'package:slang/src/builder/builder/translation_model_list_builder.dart';
import 'package:slang/src/builder/model/i18n_data.dart';
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

  group('getMissingTranslations', () {
    test('Should find missing translations', () {
      final result = _getMissingTranslations({
        'en': {
          'a': 'A',
          'b': 'B',
        },
        'de': {
          'a': 'A',
        },
      });

      expect(result[I18nLocale(language: 'de')], {'b': 'B'});
    });

    test('Should respect ignoreMissing flag', () {
      final result = _getMissingTranslations({
        'en': {
          'a': 'A',
          'b(ignoreMissing)': 'B',
        },
        'de': {
          'a': 'A',
        },
      });

      expect(result[I18nLocale(language: 'de')], isEmpty);
    });

    test('Should respect OUTDATED flag', () {
      final result = _getMissingTranslations({
        'en': {
          'a': 'A EN',
        },
        'de': {
          'a(OUTDATED)': 'A DE',
        },
      });

      expect(result[I18nLocale(language: 'de')], {'a(OUTDATED)': 'A EN'});
    });

    test('Should ignore ignoreUnused flag', () {
      final result = _getMissingTranslations({
        'en': {
          'a': 'A',
          'b(ignoreUnused)': 'B',
        },
        'de': {
          'a': 'A',
        },
      });

      expect(result[I18nLocale(language: 'de')], {'b(ignoreUnused)': 'B'});
    });

    test('Should find missing enum', () {
      final result = _getMissingTranslations({
        'en': {
          'a': 'A',
          'greet(context=Gender)': {
            'male': 'Hello Mr',
            'female': 'Hello Mrs',
          },
        },
        'de': {
          'a': 'A',
          'greet(context=Gender)': {
            'male': 'Hello Herr',
          },
        },
      });

      expect(
        result[I18nLocale(language: 'de')],
        {
          'greet(context=Gender)': {
            'female': 'Hello Mrs',
          },
        },
      );
    });
  });

  group('getUnusedTranslations', () {
    test('Should find unused translations', () {
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

    test('Should respect ignoreUnused flag', () {
      final result = _getUnusedTranslations({
        'en': {
          'a': 'A',
        },
        'de': {
          'a': 'A',
          'b(ignoreUnused)': 'B',
        },
      });

      expect(result[I18nLocale(language: 'de')], isEmpty);
    });

    test('Should ignore ignoreMissing flag', () {
      final result = _getUnusedTranslations({
        'en': {
          'a': 'A',
        },
        'de': {
          'a': 'A',
          'b(ignoreMissing)': 'B',
        },
      });

      expect(result[I18nLocale(language: 'de')], {'b(ignoreMissing)': 'B'});
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

Map<I18nLocale, Map<String, dynamic>> _getMissingTranslations(
  Map<String, Map<String, dynamic>> translations,
) {
  final existing = _buildTranslations(translations);
  return getMissingTranslations(
    baseTranslations: findBaseTranslations(RawConfig.defaultConfig, existing),
    translations: existing,
  );
}

Map<I18nLocale, Map<String, dynamic>> _getUnusedTranslations(
  Map<String, Map<String, dynamic>> translations,
) {
  final existing = _buildTranslations(translations);
  return getUnusedTranslations(
    baseTranslations: findBaseTranslations(RawConfig.defaultConfig, existing),
    rawConfig: RawConfig.defaultConfig,
    translations: _buildTranslations(translations),
    full: false,
  );
}

List<I18nData> _buildTranslations(
    Map<String, Map<String, dynamic>> translations) {
  final map = TranslationMap();
  for (final entry in translations.entries) {
    map.addTranslations(
      locale: I18nLocale(language: entry.key),
      translations: entry.value,
    );
  }

  return TranslationModelListBuilder.build(
    RawConfig.defaultConfig,
    map,
  );
}
