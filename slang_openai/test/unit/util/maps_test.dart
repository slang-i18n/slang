import 'package:slang_openai/util/maps.dart';
import 'package:test/test.dart';

void main() {
  group('removeignoreOpenai', () {
    test('Should remove one entry with ignoreMissing', () {
      final map = {
        'a(ignoreOpenai)': 'b',
        'c': 'd',
      };
      removeignoreOpenai(map: map);

      expect(map, {
        'c': 'd',
      });
    });

    test('Should remove nested entry with ignoreMissing', () {
      final map = {
        'a': {
          'b(ignoreOpenai)': 'c',
          'd': 'e',
        },
      };
      removeignoreOpenai(map: map);

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
      removeignoreOpenai(map: map);

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

      final comments = extractComments(map: map, remove: true);

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

      final comments = extractComments(map: map, remove: true);

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

      final comments = extractComments(map: map, remove: true);

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

    test('Should not remove', () {
      final map = {
        '@a': 'b',
        'c': 'd',
      };

      final comments = extractComments(map: map, remove: false);

      expect(map, {
        '@a': 'b',
        'c': 'd',
      });

      expect(comments, {
        '@a': 'b',
      });
    });
  });
}
