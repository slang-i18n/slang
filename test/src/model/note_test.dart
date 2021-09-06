import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:test/test.dart';

void main() {
  const localeEnum = 'AppLocale.en';

  group(TextNode, () {
    group(StringInterpolation.dart, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node = TextNode(test, StringInterpolation.dart, localeEnum);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = 'I have one argument named \$apple.';
        final node = TextNode(test, StringInterpolation.dart, localeEnum);
        expect(node.content, test);
        expect(node.params, {'apple'});
      });

      test('one duplicate argument', () {
        final test = 'This string has one \$argument and \$argument.';
        final node = TextNode(test, StringInterpolation.dart, localeEnum);
        expect(node.content, test);
        expect(node.params, {'argument'});
      });

      test('one argument at the beginning', () {
        final test = '\$test at the beginning.';
        final node = TextNode(test, StringInterpolation.dart, localeEnum);
        expect(node.content, test);
        expect(node.params, {'test'});
      });

      test('one escaped argument', () {
        final test = 'I have one argument named \\\$apple.';
        final node = TextNode(test, StringInterpolation.dart, localeEnum);
        expect(node.content, 'I have one argument named \\\$apple.'); // \$apple
        expect(node.params, <String>{});
      });

      test('one argument with link', () {
        final test = '\$apple is linked to @:wow!';
        final node = TextNode(test, StringInterpolation.dart, localeEnum);
        expect(node.content,
            '\$apple is linked to \${AppLocale.en.translations.wow}!');
        expect(node.params, {'apple'});
      });

      test('one argument and single dollars', () {
        final test =
            r'$ I have \$ one argument named $apple but also a $ and a $';
        final node = TextNode(test, StringInterpolation.dart, localeEnum);
        expect(node.content,
            r'\$ I have \$ one argument named $apple but also a \$ and a \$');
        expect(node.params, {'apple'});
      });
    });

    group(StringInterpolation.braces, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node = TextNode(test, StringInterpolation.braces, localeEnum);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = 'I have one argument named {apple}.';
        final node = TextNode(test, StringInterpolation.braces, localeEnum);
        expect(node.content, 'I have one argument named \$apple.');
        expect(node.params, {'apple'});
      });

      test('one argument without space', () {
        final test = 'I have one argument named{apple}.';
        final node = TextNode(test, StringInterpolation.braces, localeEnum);
        expect(node.content, 'I have one argument named\$apple.');
        expect(node.params, {'apple'});
      });

      test('one argument followed by underscore', () {
        final test = 'This string has one argument named {tom}_';
        final node = TextNode(test, StringInterpolation.braces, localeEnum);
        expect(node.content, 'This string has one argument named \${tom}_');
        expect(node.params, {'tom'});
      });

      test('one argument followed by number', () {
        final test = 'This string has one argument named {tom}7';
        final node = TextNode(test, StringInterpolation.braces, localeEnum);
        expect(node.content, 'This string has one argument named \${tom}7');
        expect(node.params, {'tom'});
      });

      test('one argument with fake arguments', () {
        final test =
            r'$ I have one argument named {apple} but this is $fake. \$ $';
        final node = TextNode(test, StringInterpolation.braces, localeEnum);
        expect(node.content,
            r'\$ I have one argument named $apple but this is \$fake. \$ \$');
        expect(node.params, {'apple'});
      });

      test('one escaped argument escaped', () {
        final test = 'I have one argument named \\{apple}.';
        final node = TextNode(test, StringInterpolation.braces, localeEnum);
        expect(node.content, 'I have one argument named {apple}.');
        expect(node.params, <String>{});
      });

      test('one argument with link', () {
        final test = '{apple} is linked to @:wow!';
        final node = TextNode(test, StringInterpolation.braces, localeEnum);
        expect(node.content,
            '\$apple is linked to \${AppLocale.en.translations.wow}!');
        expect(node.params, {'apple'});
      });
    });

    group(StringInterpolation.doubleBraces, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node =
            TextNode(test, StringInterpolation.doubleBraces, localeEnum);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = 'I have one argument named {{apple}}.';
        final node =
            TextNode(test, StringInterpolation.doubleBraces, localeEnum);
        expect(node.content, 'I have one argument named \$apple.');
        expect(node.params, {'apple'});
      });

      test('one argument followed by underscore', () {
        final test = 'This string has one argument named {{tom}}_';
        final node =
            TextNode(test, StringInterpolation.doubleBraces, localeEnum);
        expect(node.content, 'This string has one argument named \${tom}_');
        expect(node.params, {'tom'});
      });

      test('one argument followed by number', () {
        final test = 'This string has one argument named {{tom}}7';
        final node =
            TextNode(test, StringInterpolation.doubleBraces, localeEnum);
        expect(node.content, 'This string has one argument named \${tom}7');
        expect(node.params, {'tom'});
      });

      test('one fake argument', () {
        final test = 'I have one argument named \\{apple}.';
        final node =
            TextNode(test, StringInterpolation.doubleBraces, localeEnum);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one escaped argument', () {
        final test = 'I have one argument named \\{{apple}}.';
        final node =
            TextNode(test, StringInterpolation.doubleBraces, localeEnum);
        expect(node.content, 'I have one argument named {{apple}}.');
        expect(node.params, <String>{});
      });
    });
  });
}
