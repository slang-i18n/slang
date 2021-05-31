import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:test/test.dart';

void main() {
  group('TextNode', () {
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
  });
}
