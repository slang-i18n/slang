import 'package:slang/builder/utils/map_utils.dart';
import 'package:test/test.dart';

void main() {
  group('addItemToMap', () {
    test('add string to empty map', () {
      final map = <String, dynamic>{};
      MapUtils.addItemToMap(
          map: map, destinationPath: 'myPath.mySubPath', item: 'Hello World');
      expect(map, {
        'myPath': {
          'mySubPath': 'Hello World',
        },
      });
    });

    test('add string to populated map', () {
      final map = <String, dynamic>{
        'myPath': <String, dynamic>{
          'myExistingSubPath': ['1', '2', '3'],
        },
      };
      MapUtils.addItemToMap(
          map: map, destinationPath: 'myPath.mySubPath', item: 'Hello World');
      expect(map, {
        'myPath': {
          'myExistingSubPath': ['1', '2', '3'],
          'mySubPath': 'Hello World',
        },
      });
    });

    test('add list to populated map', () {
      final map = <String, dynamic>{
        'myPath': <String, dynamic>{
          'myExistingSubPath': ['1', '2', '3'],
        },
      };
      MapUtils.addItemToMap(
        map: map,
        destinationPath: 'myPath.mySubPath',
        item: ['Hello Earth', 'Hello Moon'],
      );
      expect(map, {
        'myPath': {
          'myExistingSubPath': ['1', '2', '3'],
          'mySubPath': [
            'Hello Earth',
            'Hello Moon',
          ],
        },
      });
    });

    test('add map to populated map', () {
      final map = <String, dynamic>{
        'myPath': <String, dynamic>{
          'myExistingSubPath': ['1', '2', '3'],
        },
      };
      MapUtils.addItemToMap(
        map: map,
        destinationPath: 'myPath.mySubPath',
        item: {
          'a': 3,
          'b': 'c',
        },
      );
      expect(map, {
        'myPath': {
          'myExistingSubPath': ['1', '2', '3'],
          'mySubPath': {
            'a': 3,
            'b': 'c',
          },
        },
      });
    });
  });

  group('addToList', () {
    test('add first item', () {
      final list = [];
      final added = MapUtils.addToList(
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
      final added = MapUtils.addToList(
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
      final added = MapUtils.addToList(
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
      final firstAdded = MapUtils.addToList(
        list: list,
        index: 0,
        element: 'a',
        overwrite: false,
      );
      final secondAdded = MapUtils.addToList(
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
      final added = MapUtils.addToList(
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
