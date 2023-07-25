import 'package:slang/runner/apply.dart';
import 'package:test/test.dart';

void main() {
  group('applyMapRecursive', () {
    test('ignore strings in baseMap if not applied', () {
      final result = applyMapRecursive(
        baseMap: {'c': 'C'},
        newMap: {'a': 'A'},
        oldMap: {'b': 'B'},
        verbose: false,
      );
      expect(result, {'b': 'B'});
      expect(result.keys.toList(), ['b']);
    });

    test('handle empty newMap', () {
      final map = {
        'a': {
          'aa': 'AA',
        },
      };
      final result = applyMapRecursive(
        baseMap: map,
        newMap: {},
        oldMap: map,
        verbose: false,
      );
      expect(result, map);
    });

    test('handle empty newMap (another variant)', () {
      final map = {
        'a': {
          'aa': 'AA',
        },
      };
      final result = applyMapRecursive(
        baseMap: {},
        newMap: {},
        oldMap: map,
        verbose: false,
      );
      expect(result, map);
    });

    test('ignore new strings', () {
      final result = applyMapRecursive(
        baseMap: {},
        newMap: {'d4': 'D'},
        oldMap: {'c1': 'C', 'a2': 'A', 'b3': 'B'},
        verbose: false,
      );
      expect(result, {
        'c1': 'C',
        'a2': 'A',
        'b3': 'B',
      });
      expect(result.keys.toList(), ['c1', 'a2', 'b3']);
    });

    test('add string to populated map but respect order from base', () {
      final result = applyMapRecursive(
        baseMap: {
          'c1': 'cc',
          'd4': 'dd',
          'a2': 'aa',
          'b3': 'bb',
        },
        newMap: {'d4': 'D'},
        oldMap: {'c1': 'C', 'a2': 'A', 'b3': 'B'},
        verbose: false,
      );
      expect(result, {
        'c1': 'C',
        'd4': 'D',
        'a2': 'A',
        'b3': 'B',
      });
      expect(result.keys.toList(), ['c1', 'd4', 'a2', 'b3']);
    });

    test('also reorder even if newMap is empty', () {
      final result = applyMapRecursive(
        baseMap: {
          'c': 'cc',
          'a': 'aa',
          'b': 'bb',
        },
        newMap: {},
        oldMap: {
          'b': 'B',
          'c': 'C',
          'd': 'D',
          'a': 'A',
        },
        verbose: false,
      );
      expect(result, {
        'c': 'C',
        'a': 'A',
        'b': 'B',
        'd': 'D',
      });
      expect(result.keys.toList(), ['c', 'a', 'b', 'd']);
    });

    test('also reorder the nested map', () {
      final result = applyMapRecursive(
        baseMap: {
          'c': 'cc',
          'a': {
            'w': 'ww',
            'y': 'yy',
            'x': 'xx',
            'z': 'zz',
          },
          'b': 'bb',
        },
        newMap: {
          'a': {'x': 'X'}
        },
        oldMap: {
          'c': 'C',
          'a': {
            '0': '0',
            'z': 'Z',
            'y': 'Y',
          },
          'b': 'B',
        },
        verbose: false,
      );
      expect(result, {
        'c': 'C',
        'a': {
          'y': 'Y',
          'x': 'X',
          'z': 'Z',
          '0': '0',
        },
        'b': 'B',
      });
      expect(result.keys.toList(), ['c', 'a', 'b']);
      expect((result['a'] as Map).keys.toList(), ['y', 'x', 'z', '0']);
    });
  });
}
