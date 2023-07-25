import 'package:slang_gpt/util/maps.dart';
import 'package:test/test.dart';

void main() {
  group('removeIgnoreMissing', () {
    test('Should remove one entry with ignoreMissing', () {
      final map = {
        'a(ignoreMissing)': 'b',
        'c': 'd',
      };
      removeIgnoreMissing(map: map);

      expect(map, {
        'c': 'd',
      });
    });

    test('Should remove nested entry with ignoreMissing', () {
      final map = {
        'a': {
          'b(ignoreMissing)': 'c',
          'd': 'e',
        },
      };
      removeIgnoreMissing(map: map);

      expect(map, {
        'a': {
          'd': 'e',
        },
      });
    });

    test('Should not remove anything', () {
      final map = {
        'a': 'b',
        'c': 'd',
      };
      removeIgnoreMissing(map: map);

      expect(map, {
        'a': 'b',
        'c': 'd',
      });
    });
  });

  group('extractComments', () {
    test('Should extract one comment', () {
      final map = {
        '@a': 'b',
        'c': 'd',
      };

      final comments = extractComments(map: map);

      expect(map, {
        'c': 'd',
      });

      expect(comments, {
        '@a': 'b',
      });
    });

    test('Should extract nested comment', () {
      final map = {
        'a': {
          '@b': 'c',
          'd': 'e',
        },
      };

      final comments = extractComments(map: map);

      expect(map, {
        'a': {
          'd': 'e',
        },
      });

      expect(comments, {
        'a': {
          '@b': 'c',
        },
      });
    });

    test('Should remove empty map after extraction', () {
      final map = {
        'a': {
          '@b': 'c',
        },
        'f': {
          'g': 'h',
        },
      };

      final comments = extractComments(map: map);

      expect(map, {
        'f': {
          'g': 'h',
        },
      });

      expect(comments, {
        'a': {
          '@b': 'c',
        },
      });
    });
  });
}
