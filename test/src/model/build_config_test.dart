import 'package:fast_i18n/src/model/build_config.dart';
import 'package:test/test.dart';

void main() {
  group('string interpolation digest', () {
    group('single braces', () {
      test('no arguments', () {
        String test = 'This string has no arguments.';
        expect(test.digest(StringInterpolation.braces), test);
      });

      test('one argument', () {
        expect(
            'This string has one argument named {tom}.'
                .digest(StringInterpolation.braces),
            'This string has one argument named \${tom}.');
      });

      test('two arguments', () {
        expect(
            'This string has two arguments named {tom} and {two}.'
                .digest(StringInterpolation.braces),
            'This string has two arguments named \${tom} and \${two}.');
      });

      test('one without space', () {
        expect(
            'This string has one argument named{tom}.'
                .digest(StringInterpolation.braces),
            'This string has one argument named\${tom}.');
      });

      test('escaped', () {
        String test = 'This string has one argument named \\{tom}.';
        expect(test.digest(StringInterpolation.braces), test);
      });
    });

    group('double braces', () {
      test('no arguments', () {
        String test = 'This string has no arguments.';
        expect(test.digest(StringInterpolation.doubleBraces), test);
      });

      test('one argument', () {
        expect(
            'This string has one argument named {{tom}}.'
                .digest(StringInterpolation.doubleBraces),
            'This string has one argument named \${tom}.');
      });

      test('two arguments', () {
        expect(
            'This string has two arguments named {{tom}} and {{two}}.'
                .digest(StringInterpolation.doubleBraces),
            'This string has two arguments named \${tom} and \${two}.');
      });

      test('one without space', () {
        expect(
            'This string has one argument named{{tom}}.'
                .digest(StringInterpolation.doubleBraces),
            'This string has one argument named\${tom}.');
      });

      test('escaped', () {
        String test = 'This string has one argument named \\{{tom}}.';
        expect(test.digest(StringInterpolation.doubleBraces), test);
      });
    });
  });
}
