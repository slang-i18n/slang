import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:test/test.dart';

void main() {
  group(TextNode, () {
    group(StringInterpolation.dart, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node = TextNode(test, StringInterpolation.dart);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = 'I have one argument named \$apple.';
        final node = TextNode(test, StringInterpolation.dart);
        expect(node.content, test);
        expect(node.params, {'apple'});
      });

      test('one duplicate argument', () {
        final test = 'This string has one \$argument and \$argument.';
        final node = TextNode(test, StringInterpolation.dart);
        expect(node.content, test);
        expect(node.params, {'argument'});
      });

      test('one argument at the beginning', () {
        final test = '\$test at the beginning.';
        final node = TextNode(test, StringInterpolation.dart);
        expect(node.content, test);
        expect(node.params, {'test'});
      });

      test('one escaped argument', () {
        final test = 'I have one argument named \\\$apple.';
        final node = TextNode(test, StringInterpolation.dart);
        expect(node.content, 'I have one argument named \\\$apple.'); // \$apple
        expect(node.params, <String>{});
      });
    });

    group(StringInterpolation.braces, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node = TextNode(test, StringInterpolation.braces);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = 'I have one argument named {apple}.';
        final node = TextNode(test, StringInterpolation.braces);
        expect(node.content, 'I have one argument named \$apple.');
        expect(node.params, {'apple'});
      });

      test('one argument without space', () {
        final test = 'I have one argument named{apple}.';
        final node = TextNode(test, StringInterpolation.braces);
        expect(node.content, 'I have one argument named\$apple.');
        expect(node.params, {'apple'});
      });

      test('one argument followed by underscore', () {
        final test = 'This string has one argument named {tom}_';
        final node = TextNode(test, StringInterpolation.braces);
        expect(node.content, 'This string has one argument named \${tom}_');
        expect(node.params, {'tom'});
      });

      test('one argument followed by number', () {
        final test = 'This string has one argument named {tom}7';
        final node = TextNode(test, StringInterpolation.braces);
        expect(node.content, 'This string has one argument named \${tom}7');
        expect(node.params, {'tom'});
      });

      test('one argument with fake argument', () {
        final test = 'I have one argument named {apple} but this is \$fake.';
        final node = TextNode(test, StringInterpolation.braces);
        expect(node.content,
            'I have one argument named \$apple but this is \$fake.');
        expect(node.params, {'apple'});
      });

      test('one escaped argument escaped', () {
        final test = 'I have one argument named \\{apple}.';
        final node = TextNode(test, StringInterpolation.braces);
        expect(node.content, 'I have one argument named {apple}.');
        expect(node.params, <String>{});
      });
    });

    group(StringInterpolation.doubleBraces, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node = TextNode(test, StringInterpolation.doubleBraces);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = 'I have one argument named {{apple}}.';
        final node = TextNode(test, StringInterpolation.doubleBraces);
        expect(node.content, 'I have one argument named \$apple.');
        expect(node.params, {'apple'});
      });

      test('one argument followed by underscore', () {
        final test = 'This string has one argument named {{tom}}_';
        final node = TextNode(test, StringInterpolation.doubleBraces);
        expect(node.content, 'This string has one argument named \${tom}_');
        expect(node.params, {'tom'});
      });

      test('one argument followed by number', () {
        final test = 'This string has one argument named {{tom}}7';
        final node = TextNode(test, StringInterpolation.doubleBraces);
        expect(node.content, 'This string has one argument named \${tom}7');
        expect(node.params, {'tom'});
      });

      test('one fake argument', () {
        final test = 'I have one argument named \\{apple}.';
        final node = TextNode(test, StringInterpolation.doubleBraces);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one escaped argument', () {
        final test = 'I have one argument named \\{{apple}}.';
        final node = TextNode(test, StringInterpolation.doubleBraces);
        expect(node.content, 'I have one argument named {{apple}}.');
        expect(node.params, <String>{});
      });
    });
  });
}
