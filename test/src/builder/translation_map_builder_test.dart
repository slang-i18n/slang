import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:test/test.dart';

void main() {
  group(TranslationMapBuilder.addToList, () {
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
      expect(added, false);
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
