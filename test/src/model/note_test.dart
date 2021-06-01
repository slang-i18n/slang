import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:test/test.dart';

void main() {
  group(TextNode, () {
    test('no arguments', () {
      final test = 'No arguments';
      final node = TextNode(test, StringInterpolation.dart);
      expect(node.content, test);
      expect(node.params, []);
    });

    test('one argument (dart)', () {
      final test = 'I have one argument named \$apple.';
      final node = TextNode(test, StringInterpolation.dart);
      expect(node.content, test);
      expect(node.params, ['apple']);
    });

    test('one argument (single braces)', () {
      final test = 'I have one argument named {apple}.';
      final node = TextNode(test, StringInterpolation.braces);
      expect(node.content, 'I have one argument named \${apple}.');
      expect(node.params, ['apple']);
    });

    test('one argument (single braces)', () {
      final test = 'I have one argument named {apple}.';
      final node = TextNode(test, StringInterpolation.braces);
      expect(node.content, 'I have one argument named \${apple}.');
      expect(node.params, ['apple']);
    });

    test('one argument without space (single braces)', () {
      final test = 'I have one argument named{apple}.';
      final node = TextNode(test, StringInterpolation.braces);
      expect(node.content, 'I have one argument named\${apple}.');
      expect(node.params, ['apple']);
    });

    test('one argument (single braces) with fake argument', () {
      final test = 'I have one argument named {apple} but this is \$fake.';
      final node = TextNode(test, StringInterpolation.braces);
      expect(node.content,
          'I have one argument named \${apple} but this is \$fake.');
      expect(node.params, ['apple']);
    });

    test('one argument (double braces)', () {
      final test = 'I have one argument named {{apple}}.';
      final node = TextNode(test, StringInterpolation.doubleBraces);
      expect(node.content, 'I have one argument named \${apple}.');
      expect(node.params, ['apple']);
    });

    test('one argument (escaped, dart)', () {
      final test = 'I have one argument named \\\$apple.';
      final node = TextNode(test, StringInterpolation.dart);
      expect(node.content, 'I have one argument named \\\$apple.'); // \$apple
      expect(node.params, []);
    });

    test('one argument (escaped, braces)', () {
      final test = 'I have one argument named \\{apple}.';
      final node = TextNode(test, StringInterpolation.braces);
      expect(node.content, 'I have one argument named {apple}.');
      expect(node.params, []);
    });

    test('one argument (escaped, double braces)', () {
      final test = 'I have one argument named \\{{apple}}.';
      final node = TextNode(test, StringInterpolation.doubleBraces);
      expect(node.content, 'I have one argument named {{apple}}.');
      expect(node.params, []);
    });

    test('one fake argument (double braces)', () {
      final test = 'I have one argument named \\{apple}.';
      final node = TextNode(test, StringInterpolation.doubleBraces);
      expect(node.content, test);
      expect(node.params, []);
    });
  });

  group('normalizeStringInterpolation', () {
    group('single braces', () {
      test('no arguments', () {
        String test = 'This string has no arguments.';
        expect(test.normalizeStringInterpolation(StringInterpolation.braces),
            test);
      });

      test('one argument', () {
        expect(
            'This string has one argument named {tom}.'
                .normalizeStringInterpolation(StringInterpolation.braces),
            'This string has one argument named \${tom}.');
      });

      test('two arguments', () {
        expect(
            'This string has two arguments named {tom} and {two}.'
                .normalizeStringInterpolation(StringInterpolation.braces),
            'This string has two arguments named \${tom} and \${two}.');
      });

      test('one without space', () {
        expect(
            'This string has one argument named{tom}.'
                .normalizeStringInterpolation(StringInterpolation.braces),
            'This string has one argument named\${tom}.');
      });

      test('escaped', () {
        String test = 'This string has one argument named \\{tom}.';
        expect(test.normalizeStringInterpolation(StringInterpolation.braces),
            'This string has one argument named {tom}.');
      });
    });

    group('double braces', () {
      test('no arguments', () {
        String test = 'This string has no arguments.';
        expect(
            test.normalizeStringInterpolation(StringInterpolation.doubleBraces),
            test);
      });

      test('one argument', () {
        expect(
            'This string has one argument named {{tom}}.'
                .normalizeStringInterpolation(StringInterpolation.doubleBraces),
            'This string has one argument named \${tom}.');
      });

      test('two arguments', () {
        expect(
            'This string has two arguments named {{tom}} and {{two}}.'
                .normalizeStringInterpolation(StringInterpolation.doubleBraces),
            'This string has two arguments named \${tom} and \${two}.');
      });

      test('one without space', () {
        expect(
            'This string has one argument named{{tom}}.'
                .normalizeStringInterpolation(StringInterpolation.doubleBraces),
            'This string has one argument named\${tom}.');
      });

      test('escaped', () {
        String test = 'This string has one argument named \\{{tom}}.';
        expect(
            test.normalizeStringInterpolation(StringInterpolation.doubleBraces),
            'This string has one argument named {{tom}}.');
      });
    });
  });

  group('parseArguments', () {
    test('no arguments', () {
      String test = 'This string has no arguments.';
      expect(test.parseArguments(StringInterpolation.braces), []);
    });

    test('one argument', () {
      String test = 'This string has one \$argument.';
      expect(test.parseArguments(StringInterpolation.dart), ['argument']);
    });

    test('one duplicate argument', () {
      String test = 'This string has one \$argument and \$argument.';
      expect(test.parseArguments(StringInterpolation.dart), ['argument']);
    });

    test('one argument at the beginning (dart)', () {
      String test = '\$test at the beginning.';
      expect(test.parseArguments(StringInterpolation.dart), ['test']);
    });

    test('one argument at the beginning (braces)', () {
      String test = '{test} at the beginning.';
      expect(test.parseArguments(StringInterpolation.braces), ['test']);
    });

    test('one argument at the beginning (double braces)', () {
      String test = '{{test}} at the beginning.';
      expect(test.parseArguments(StringInterpolation.doubleBraces), ['test']);
    });
  });
}
