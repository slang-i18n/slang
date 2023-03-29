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

  group('updateEntry', () {
    test('should update the leaf node correctly', () {
      final map = {
        'a': {
          'b': {
            'c': 42,
          },
        },
      };

      MapUtils.updateEntry(
        map: map,
        path: 'a.b.c',
        update: (key, value) => MapEntry(key, (value as int) * 2),
      );

      expect(map['a']!['b']!['c'], 84);
    });

    test('should update the leaf key correctly', () {
      final map = {
        'a': {
          'b': {
            'c': 42,
          },
        },
      };

      MapUtils.updateEntry(
        map: map,
        path: 'a.b.c',
        update: (key, value) => MapEntry('d', (value as int) * 2),
      );

      expect(map['a']!['b']!['d'], 84);
      expect(map['a']!['b']!['c'], null);
    });

    test('should keep order', () {
      final map = {
        'a': {
          'b': {
            'c0': 3,
            'c1': 4,
            'c2': 5,
          },
        },
      };

      MapUtils.updateEntry(
        map: map,
        path: 'a.b.c1',
        update: (key, value) => MapEntry('d', (value as int) * 2),
      );

      expect(map['a']!['b']!['d'], 8);
      expect(map['a']!['b']!.keys, ['c0', 'd', 'c2']);
    });

    test('should update the leaf key correctly while ignoring modifiers', () {
      final map = {
        'a': {
          'b(rich)': {
            'c(ignore)': 42,
          },
        },
      };

      MapUtils.updateEntry(
        map: map,
        path: 'a.b.c',
        update: (key, value) => MapEntry('d(nice)', (value as int) * 2),
      );

      expect(map['a']!['b(rich)']!['d(nice)'], 84);
      expect(map['a']!['b(rich)']!['c(ignore)'], null);
    });

    test('should throw an error if the path does not exist', () {
      final map = {
        'a': {
          'b': {
            'c(rich)': 42,
          },
        },
      };

      expect(
        () => MapUtils.updateEntry(
          map: map,
          path: 'a.b.d',
          update: (key, value) => MapEntry(key, value),
        ),
        throwsA(
          isA<String>().having(
            (s) => s,
            'error message',
            'The leaf "a.b.d" cannot be updated because it does not exist.',
          ),
        ),
      );
    });
  });
}
