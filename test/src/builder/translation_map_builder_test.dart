import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:test/test.dart';

void main() {
  group('TranslationMapBuilder.fromString', () {
    group(FileType.csv, () {
      test('wrong order', () {
        expect(
          () => TranslationMapBuilder.fromString(
            FileType.csv,
            [
              'key,en,de',
              'onboarding.pages.1.title,Second Page,Zweite Seite',
              'onboarding.pages.0.title,First Page,Erste Seite',
              'onboarding.pages.0.content,First Page Content,Erster Seiteninhalt',
            ].join('\r\n'),
          ),
          throwsA(
              'The leaf "onboarding.pages.1.title" cannot be added because there are missing indices.'),
        );
      });
    });
  });

  group('TranslationMapBuilder.addToList', () {
    test('add first item', () {
      final list = [];
      final added = TranslationMapBuilder.addToList(
        list: list,
        index: 0,
        element: 'a',
        overwrite: false,
      );
      expect(list, ['a']);
      expect(added, true);
    });

    test('no overwrite', () {
      final list = ['a', 'b'];
      final added = TranslationMapBuilder.addToList(
        list: list,
        index: 1,
        element: 'b modified',
        overwrite: false,
      );
      expect(list, ['a', 'b']);
      expect(added, true);
    });

    test('with overwrite', () {
      final list = ['a', 'b'];
      final added = TranslationMapBuilder.addToList(
        list: list,
        index: 1,
        element: 'b modified',
        overwrite: true,
      );
      expect(list, ['a', 'b modified']);
      expect(added, true);
    });

    test('add two items', () {
      final list = [];
      final firstAdded = TranslationMapBuilder.addToList(
        list: list,
        index: 0,
        element: 'a',
        overwrite: false,
      );
      final secondAdded = TranslationMapBuilder.addToList(
        list: list,
        index: 1,
        element: 'b',
        overwrite: false,
      );
      expect(list, ['a', 'b']);
      expect(firstAdded, true);
      expect(secondAdded, true);
    });

    test('add item with missing indices should fail', () {
      final list = ['a'];
      final added = TranslationMapBuilder.addToList(
        list: list,
        index: 3,
        element: 'b',
        overwrite: true,
      );
      expect(list, ['a']);
      expect(added, false);
    });
  });
}
