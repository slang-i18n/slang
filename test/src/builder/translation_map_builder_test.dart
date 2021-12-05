import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:test/test.dart';

void main() {
  group(TranslationMapBuilder.addAndFill, () {
    test('add first item', () {
      final list = [];
      TranslationMapBuilder.addAndFill(
        list: list,
        index: 0,
        element: 'a',
        overwrite: false,
      );
      expect(list, ['a']);
    });

    test('no overwrite', () {
      final list = [null, 'b'];
      TranslationMapBuilder.addAndFill(
        list: list,
        index: 1,
        element: 'b modified',
        overwrite: false,
      );
      expect(list, [null, 'b']);
    });

    test('with overwrite', () {
      final list = [null, 'b'];
      TranslationMapBuilder.addAndFill(
        list: list,
        index: 1,
        element: 'b modified',
        overwrite: true,
      );
      expect(list, [null, 'b modified']);
    });

    test('add two items', () {
      final list = [];
      TranslationMapBuilder.addAndFill(
        list: list,
        index: 0,
        element: 'a',
        overwrite: false,
      );
      TranslationMapBuilder.addAndFill(
        list: list,
        index: 1,
        element: 'b',
        overwrite: false,
      );
      expect(list, ['a', 'b']);
    });

    test('add two items with skip', () {
      final list = [];
      TranslationMapBuilder.addAndFill(
        list: list,
        index: 1,
        element: 'a',
        overwrite: false,
      );
      TranslationMapBuilder.addAndFill(
        list: list,
        index: 3,
        element: 'b',
        overwrite: false,
      );
      expect(list, [null, 'a', null, 'b']);
    });

    test('add two items with skip reverse', () {
      final list = [];
      TranslationMapBuilder.addAndFill(
        list: list,
        index: 3,
        element: 'b',
        overwrite: false,
      );
      TranslationMapBuilder.addAndFill(
        list: list,
        index: 1,
        element: 'a',
        overwrite: false,
      );
      expect(list, [null, 'a', null, 'b']);
    });
  });
}
