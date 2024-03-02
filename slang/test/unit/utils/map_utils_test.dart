import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:test/test.dart';

void main() {
  group('getValueAtPath', () {
    test('get string from empty map', () {
      final item = MapUtils.getValueAtPath(
        map: {},
        path: 'myPath.mySubPath.mySubSubPath',
      );
      expect(item, null);
    });

    test('get string from populated map', () {
      final item = MapUtils.getValueAtPath(
        map: {
          'myPath': {
            'myFirstSubPath': 'Hello',
            'mySubPath': {
              'mySubSubPath': 'Hello World',
            },
          },
        },
        path: 'myPath.mySubPath.mySubSubPath',
      );
      expect(item, 'Hello World');
    });
  });

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

      final result = MapUtils.updateEntry(
        map: map,
        path: 'a.b.c',
        update: (key, value) => MapEntry(key, (value as int) * 2),
      );

      expect(result, true);
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

      final result = MapUtils.updateEntry(
        map: map,
        path: 'a.b.c',
        update: (key, value) => MapEntry('d', (value as int) * 2),
      );

      expect(result, true);
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

      final result = MapUtils.updateEntry(
        map: map,
        path: 'a.b.c1',
        update: (key, value) => MapEntry('d', (value as int) * 2),
      );

      expect(result, true);
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

      final result = MapUtils.updateEntry(
        map: map,
        path: 'a.b.c',
        update: (key, value) => MapEntry('d(nice)', (value as int) * 2),
      );

      expect(result, true);
      expect(map['a']!['b(rich)']!['d(nice)'], 84);
      expect(map['a']!['b(rich)']!['c(ignore)'], null);
    });

    test('should return false if the path does not exist', () {
      final map = {
        'a': {
          'b': {
            'c(rich)': 42,
          },
        },
      };

      final result = MapUtils.updateEntry(
        map: map,
        path: 'a.b.d',
        update: (key, value) => MapEntry(key, value),
      );

      expect(result, false);
    });
  });

  group('deleteEntry', () {
    test('should delete single node correctly', () {
      final map = {
        'a': 'b',
      };

      final result = MapUtils.deleteEntry(
        map: map,
        path: 'a',
      );

      expect(result, true);
      expect(map.isEmpty, true);
    });

    test('should delete the leaf node correctly', () {
      final map = {
        'a': {
          'b': {
            'c': 42,
            'd': 43,
          },
        },
      };

      final result = MapUtils.deleteEntry(
        map: map,
        path: 'a.b.c',
      );

      expect(result, true);
      expect(map['a']!['b']!['c'], null);
      expect(map['a']!['b']!['d'], 43);
    });
  });

  group('subtract', () {
    test('Should subtract a single value', () {
      final result = MapUtils.subtract(
        target: {'a': 42},
        other: {'a': 33},
      );

      expect(result, {});
    });

    test('Should ignore missing values', () {
      final result = MapUtils.subtract(
        target: {'a': 42},
        other: {'b': 33},
      );

      expect(result, {'a': 42});
    });

    test('Should keep whole map', () {
      final result = MapUtils.subtract(
        target: {
          'a': 42,
          'b': {
            'a': true,
          }
        },
        other: {
          'a': 42,
        },
      );

      expect(result, {
        'b': {
          'a': true,
        }
      });
    });

    test('Should subtract map partially', () {
      final result = MapUtils.subtract(
        target: {
          'a': 42,
          'b': {
            'c': true,
            'd': false,
          }
        },
        other: {
          'a': 42,
          'b': {
            'c': true,
          },
        },
      );

      expect(result, {
        'b': {
          'd': false,
        },
      });
    });
  });

  group('getFlatMap', () {
    test('Should return empty list', () {
      final result = MapUtils.getFlatMap({});

      expect(result, []);
    });

    test('Should return single entry', () {
      final result = MapUtils.getFlatMap({
        'a': 42,
      });

      expect(result, ['a']);
    });

    test('Should return multiple entries', () {
      final result = MapUtils.getFlatMap({
        'a': 42,
        'b': 43,
      });

      expect(result, ['a', 'b']);
    });

    test('Should return nested entry', () {
      final result = MapUtils.getFlatMap({
        'a': {
          'b': 42,
        },
      });

      expect(result, ['a.b']);
    });

    test('Should return multiple nested entries', () {
      final result = MapUtils.getFlatMap({
        'a': {
          'b': 42,
          'c': 43,
          'd': {
            'e': 44,
          },
        },
      });

      expect(result, ['a.b', 'a.c', 'a.d.e']);
    });

    test('Should treat a list as a leaf', () {
      final result = MapUtils.getFlatMap({
        'a': {
          'b': [1, 2],
        },
      });

      expect(result, ['a.b']);
    });
  });

  group('clearEmptyMaps', () {
    test('Should clear empty map', () {
      final map = {
        'a': {},
      };
      MapUtils.clearEmptyMaps(map);

      expect(map, {});
    });

    test('Should clear nested empty maps', () {
      final map = {
        'a': {
          'b': {},
          'not removed': 'c',
          'c': {
            'd': {},
          },
        },
        'e': 42,
      };
      MapUtils.clearEmptyMaps(map);

      expect(map, {
        'a': {
          'not removed': 'c',
        },
        'e': 42,
      });
    });
  });
}
