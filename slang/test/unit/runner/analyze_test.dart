import 'dart:io';

import 'package:slang/src/builder/builder/translation_model_list_builder.dart';
import 'package:slang/src/builder/model/i18n_data.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:slang/src/runner/analyze.dart';
import 'package:test/test.dart';

import '../../util/mocks/fake_file.dart';

void main() {

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

  group('TranslationUsageAnalyzer - AST-based analysis', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('slang_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('detects direct translation usage', () {
      final code = '''
        void main() {
          print(t.mainScreen.title);
          print(t.mainScreen.subtitle);
        }
      ''';
      final testFile = File('${tempDir.path}/test.dart');
      testFile.writeAsStringSync(code);

      final analyzer = TranslationUsageAnalyzer(translateVar: 't');
      final usedPaths = analyzer.analyzeFile(testFile.path);

      expect(usedPaths, contains('mainScreen.title'));
      expect(usedPaths, contains('mainScreen.subtitle'));
    });

    test('detects simple variable assignment and usage', () {
      final code = '''
        void main() {
          final title = t.mainScreen.title;
          final subtitle = t.mainScreen.subtitle;
        
          print(title);
          print(subtitle);
        }
      ''';
      final testFile = File('${tempDir.path}/test.dart');
      testFile.writeAsStringSync(code);

      final analyzer = TranslationUsageAnalyzer(translateVar: 't');
      final usedPaths = analyzer.analyzeFile(testFile.path);

      expect(usedPaths, contains('mainScreen.title'));
      expect(usedPaths, contains('mainScreen.subtitle'));
    });

    test('detects nested variable assignment', () {
      final code = '''
        void main() {
          final screen = t.mainScreen;
          final title = screen.title;
          final subtitle = screen.subtitle;
        
          print(title);
          print(subtitle);
        }
      ''';
      final testFile = File('${tempDir.path}/test.dart');
      testFile.writeAsStringSync(code);

      final analyzer = TranslationUsageAnalyzer(translateVar: 't');
      final usedPaths = analyzer.analyzeFile(testFile.path);

      expect(usedPaths, contains('mainScreen.title'));
      expect(usedPaths, contains('mainScreen.subtitle'));
    });

    test('detects context.t usage', () {
      final code = '''
        void main(BuildContext context) {
          print(context.t.mainScreen.title);
          print(context.t.mainScreen.subtitle);
        }
      ''';
      final testFile = File('${tempDir.path}/test.dart');
      testFile.writeAsStringSync(code);

      final analyzer = TranslationUsageAnalyzer(translateVar: 't');
      final usedPaths = analyzer.analyzeFile(testFile.path);

      expect(usedPaths, contains('mainScreen.title'));
      expect(usedPaths, contains('mainScreen.subtitle'));
    });

    test('detects complex nested property access', () {
      final code = '''
        void main() {
          final app = t.app;
          final mainScreen = app.screen;
          final dialog = mainScreen.dialog;
        
          final title = dialog.title;
          final message = dialog.message;
        
          print(title);
          print(message);
        }
      ''';
      final testFile = File('${tempDir.path}/test.dart');
      testFile.writeAsStringSync(code);

      final analyzer = TranslationUsageAnalyzer(translateVar: 't');
      final usedPaths = analyzer.analyzeFile(testFile.path);

      expect(usedPaths, contains('app.screen.dialog.title'));
      expect(usedPaths, contains('app.screen.dialog.message'));
    });

    test('handles mixed usage patterns', () {
      final code = '''
        void main(BuildContext context) {
          // Direct usage
          print(t.direct.title);
        
          // Variable assignment
          final screen = t.mainScreen;
          final headerTitle = screen.header.title;
        
          // Context usage
          final contextTitle = context.t.context.title;
        
          // Nested usage
          final nested = t.nested.deep.very;
          final deepValue = nested.value;
        
          print(headerTitle);
          print(contextTitle);
          print(deepValue);
        }
      ''';
      final testFile = File('${tempDir.path}/test.dart');
      testFile.writeAsStringSync(code);

      final analyzer = TranslationUsageAnalyzer(translateVar: 't');
      final usedPaths = analyzer.analyzeFile(testFile.path);

      expect(usedPaths, contains('direct.title'));
      expect(usedPaths, contains('mainScreen.header.title'));
      expect(usedPaths, contains('context.title'));
      expect(usedPaths, contains('nested.deep.very.value'));
    });

    test('ignores unused translations', () {
      final code = '''
        void main() {
          final used = t.mainScreen.title;
          print(used);
        
          // t.mainScreen.subtitle is not used anywhere
        }
      ''';
      final testFile = File('${tempDir.path}/test.dart');
      testFile.writeAsStringSync(code);

      final analyzer = TranslationUsageAnalyzer(translateVar: 't');
      final usedPaths = analyzer.analyzeFile(testFile.path);

      expect(usedPaths, contains('mainScreen.title'));
      expect(usedPaths, isNot(contains('mainScreen.subtitle')));
    });

    test('handles function parameters', () {
      final code = '''
        void main() {
          final title = t.mainScreen.title;
          showMessage(title);
        }
        
        void showMessage(String message) {
          print(message);
        }
      ''';
      final testFile = File('${tempDir.path}/test.dart');
      testFile.writeAsStringSync(code);

      final analyzer = TranslationUsageAnalyzer(translateVar: 't');
      final usedPaths = analyzer.analyzeFile(testFile.path);

      expect(usedPaths, contains('mainScreen.title'));
    });

    test('handles variable reassignment', () {
      final code = '''
        void main() {
          var title = t.mainScreen.title;
          print(title);
        
          title = t.otherScreen.title; // reassign
          print(title);
        }
      ''';
      final testFile = File('${tempDir.path}/test.dart');
      testFile.writeAsStringSync(code);

      final analyzer = TranslationUsageAnalyzer(translateVar: 't');
      final usedPaths = analyzer.analyzeFile(testFile.path);

      expect(usedPaths, contains('mainScreen.title'));
      expect(usedPaths, contains('otherScreen.title'));
    });

    test('handles conditional expressions', () {
      final code = '''
        void main() {
          final isMain = true;
          final title = isMain ? t.mainScreen.title : t.otherScreen.title;
          print(title);
        }
      ''';
      final testFile = File('${tempDir.path}/test.dart');
      testFile.writeAsStringSync(code);

      final analyzer = TranslationUsageAnalyzer(translateVar: 't');
      final usedPaths = analyzer.analyzeFile(testFile.path);

      expect(usedPaths, contains('mainScreen.title'));
      expect(usedPaths, contains('otherScreen.title'));
    });
  });
}

Map<I18nLocale, Map<String, dynamic>> _getMissingTranslations(
    Map<String, Map<String, dynamic>> translations,
    ) {
  return getMissingTranslations(
    rawConfig: RawConfig.defaultConfig,
    translations: _buildTranslations(translations),
  );
}

Map<I18nLocale, Map<String, dynamic>> _getUnusedTranslations(
    Map<String, Map<String, dynamic>> translations,
    ) {
  return getUnusedTranslations(
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
