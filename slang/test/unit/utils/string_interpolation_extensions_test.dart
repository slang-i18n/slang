import 'package:slang/src/builder/utils/string_interpolation_extensions.dart';
import 'package:test/test.dart';

String _replacer(String s) {
  return 'X';
}

extension on String {
  String dart() => replaceDartInterpolation(
        replacer: _replacer,
      );

  String braces() => replaceBracesInterpolation(
        replacer: _replacer,
      );

  String doubleBraces() => replaceDoubleBracesInterpolation(
        replacer: _replacer,
      );
}

void main() {
  group('dart', () {
    test('no matches', () {
      final input = 'Hello World';
      expect(input.dart(), input);
    });

    test('match only', () {
      final input = r'${m!<-~}';
      expect(input.dart(), 'X');
    });

    test('match only dollar', () {
      final input = r'$mam';
      expect(input.dart(), 'X');
    });

    test('match start', () {
      final input = r'${m!<-~} Hello';
      expect(input.dart(), 'X Hello');
    });

    test('match end', () {
      final input = r'Hello ${m!<-~}';
      expect(input.dart(), 'Hello X');
    });

    test('start with closing bracket', () {
      final input = r'} $a';
      expect(input.dart(), '} X');
    });

    test('dollar in the middle', () {
      final input = r'$a $ ';
      expect(input.dart(), r'X $ ');
    });

    test('ends with dollar', () {
      final input = r'$a $';
      expect(input.dart(), r'X $');
    });

    test('ends with missing closing bracket', () {
      final input = r'$a ${bc';
      expect(input.dart(), r'X ${bc');
    });
  });

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

    test('ignore \\{{ at the start', () {
      final input = '\\{{ World!';
      expect(input.doubleBraces(), '{{ World!');
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
