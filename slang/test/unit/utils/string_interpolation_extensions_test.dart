import 'package:slang/builder/utils/string_interpolation_extensions.dart';
import 'package:test/test.dart';

String _replacer(String s) {
  return 'X';
}

extension on String {
  String braces() => replaceBracesInterpolation(
        replace: _replacer,
      );

  String doubleBraces() => replaceDoubleBracesInterpolation(
        replace: _replacer,
      );
}

void main() {
  group('braces', () {
    test('no matches', () {
      final input = 'Hello World';
      expect(input.braces(), input);
    });

    test('match only', () {
      final input = '{m!<-~}';
      expect(input.braces(), 'X');
    });

    test('match start', () {
      final input = '{m!<-~} Hello';
      expect(input.braces(), 'X Hello');
    });

    test('match end', () {
      final input = 'Hello {m!<-~}';
      expect(input.braces(), 'Hello X');
    });

    test('start with closing bracket', () {
      final input = '} {a}';
      expect(input.braces(), '} X');
    });

    test('ends with opening bracket', () {
      final input = '{a} {';
      expect(input.braces(), 'X {');
    });

    test('has double braces instead single braces', () {
      final input = 'Hello {{a}} {{b}}';
      expect(input.braces(), 'Hello X} X}');
    });

    test('ignore \\{ only', () {
      final input = 'Hello \\{ World!';
      expect(input.braces(), 'Hello { World!');
    });

    test('ignore \\{ and another match', () {
      final input = 'Hello \\{ World {arg}!';
      expect(input.braces(), 'Hello { World X!');
    });
  });

  group('double braces', () {
    test('no matches', () {
      final input = 'Hello World';
      expect(input.doubleBraces(), input);
    });

    test('match only', () {
      final input = '{{m!<-~}}';
      expect(input.doubleBraces(), 'X');
    });

    test('match start', () {
      final input = '{{m!<-~}} Hello';
      expect(input.doubleBraces(), 'X Hello');
    });

    test('match end', () {
      final input = 'Hello {{m!<-~}}';
      expect(input.doubleBraces(), 'Hello X');
    });

    test('start with closing bracket', () {
      final input = '}} {{a}}';
      expect(input.doubleBraces(), '}} X');
    });

    test('ends with opening bracket', () {
      final input = '{{a}} {{';
      expect(input.doubleBraces(), 'X {{');
    });

    test('ignore \\{{ only', () {
      final input = 'Hello \\{{ World!';
      expect(input.doubleBraces(), 'Hello {{ World!');
    });

    test('ignore \\{{ end', () {
      final input = 'Hello World! \\{{';
      expect(input.doubleBraces(), 'Hello World! {{');
    });

    test('ignore \\{{ and another match', () {
      final input = 'Hello \\{{ World {{arg}}!';
      expect(input.doubleBraces(), 'Hello {{ World X!');
    });
  });
}
