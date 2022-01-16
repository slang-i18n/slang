import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:test/test.dart';

void main() {
  group(ListNode, () {
    final interpolation = StringInterpolation.braces;

    test('Plain strings', () {
      final node = ListNode(path: '', entries: [
        TextNode(
          path: '',
          raw: 'Hello',
          interpolation: interpolation,
        ),
        TextNode(
          path: '',
          raw: 'Hi',
          interpolation: interpolation,
        ),
      ]);

      expect(node.genericType, 'String');
    });

    test('Parameterized strings', () {
      final node = ListNode(path: '', entries: [
        TextNode(
          path: '',
          raw: 'Hello',
          interpolation: interpolation,
        ),
        TextNode(
          path: '',
          raw: 'Hi {name}',
          interpolation: interpolation,
        ),
      ]);

      expect(node.genericType, 'dynamic');
    });

    test('Nested list', () {
      final node = ListNode(path: '', entries: [
        ListNode(path: '', entries: [
          TextNode(
            path: '',
            raw: 'Hello',
            interpolation: interpolation,
          ),
          TextNode(
            path: '',
            raw: 'Hi {name}',
            interpolation: interpolation,
          ),
        ]),
        ListNode(path: '', entries: [
          TextNode(
            path: '',
            raw: 'Hello',
            interpolation: interpolation,
          ),
          TextNode(
            path: '',
            raw: 'Hi {name}',
            interpolation: interpolation,
          ),
        ]),
      ]);

      expect(node.genericType, 'List<dynamic>');
    });

    test('Deeper Nested list', () {
      final node = ListNode(path: '', entries: [
        ListNode(path: '', entries: [
          ListNode(path: '', entries: [
            TextNode(
              path: '',
              raw: 'Hello',
              interpolation: interpolation,
            ),
            TextNode(
              path: '',
              raw: 'Hi',
              interpolation: interpolation,
            ),
          ]),
        ]),
        ListNode(path: '', entries: [
          ListNode(path: '', entries: [
            TextNode(
              path: '',
              raw: 'Hello',
              interpolation: interpolation,
            ),
            TextNode(
              path: '',
              raw: 'Hi',
              interpolation: interpolation,
            ),
          ]),
          ListNode(path: '', entries: [
            TextNode(
              path: '',
              raw: 'Hello',
              interpolation: interpolation,
            ),
            TextNode(
              path: '',
              raw: 'Hi',
              interpolation: interpolation,
            )
          ]),
        ]),
      ]);

      expect(node.genericType, 'List<List<String>>');
    });

    test('Class', () {
      final node = ListNode(path: '', entries: [
        ObjectNode(
          path: '',
          entries: {
            'key0': TextNode(
              path: '',
              raw: 'Hi',
              interpolation: interpolation,
            ),
          },
          isMap: false,
        ),
        ObjectNode(
          path: '',
          entries: {
            'key0': TextNode(
              path: '',
              raw: 'Hi',
              interpolation: interpolation,
            ),
          },
          isMap: false,
        ),
      ]);

      expect(node.genericType, 'dynamic');
    });

    test('Map', () {
      final node = ListNode(path: '', entries: [
        ObjectNode(
          path: '',
          entries: {
            'key0': TextNode(
              path: '',
              raw: 'Hi',
              interpolation: interpolation,
            ),
          },
          isMap: true,
        ),
        ObjectNode(
          path: '',
          entries: {
            'key0': TextNode(
              path: '',
              raw: 'Hi',
              interpolation: interpolation,
            ),
          },
          isMap: true,
        ),
      ]);

      expect(node.genericType, 'Map<String, String>');
    });
  });

  group(TextNode, () {
    group(StringInterpolation.dart, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node = TextNode.test(test, StringInterpolation.dart);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = 'I have one argument named \$apple.';
        final node = TextNode.test(test, StringInterpolation.dart);
        expect(node.content, test);
        expect(node.params, {'apple'});
      });

      test('one duplicate argument', () {
        final test = 'This string has one \$argument and \$argument.';
        final node = TextNode.test(test, StringInterpolation.dart);
        expect(node.content, test);
        expect(node.params, {'argument'});
      });

      test('one argument at the beginning', () {
        final test = '\$test at the beginning.';
        final node = TextNode.test(test, StringInterpolation.dart);
        expect(node.content, test);
        expect(node.params, {'test'});
      });

      test('one escaped argument', () {
        final test = 'I have one argument named \\\$apple.';
        final node = TextNode.test(test, StringInterpolation.dart);
        expect(node.content, 'I have one argument named \\\$apple.'); // \$apple
        expect(node.params, <String>{});
      });

      test('one argument with link', () {
        final test = '\$apple is linked to @:wow!';
        final node = TextNode.test(test, StringInterpolation.dart);
        expect(node.content,
            '\$apple is linked to \${AppLocale.en.translations.wow}!');
        expect(node.params, {'apple'});
      });

      test('one argument and single dollars', () {
        final test =
            r'$ I have \$ one argument named $apple but also a $ and a $';
        final node = TextNode.test(test, StringInterpolation.dart);
        expect(node.content,
            r'\$ I have \$ one argument named $apple but also a \$ and a \$');
        expect(node.params, {'apple'});
      });

      test('with case', () {
        final test = r'Nice $cool_hi $wow ${yes} ${no_yes} @:hello_world.yes';
        final node =
            TextNode.test(test, StringInterpolation.dart, CaseStyle.camel);
        expect(node.content,
            r'Nice $coolHi $wow ${yes} ${noYes} ${AppLocale.en.translations.hello_world.yes}');
        expect(node.params, {'coolHi', 'wow', 'yes', 'noYes'});
      });

      test('with links', () {
        final test = r'@:.c @:a @:hi @:wow. @:nice.cool';
        final node = TextNode.test(test, StringInterpolation.dart);
        expect(node.content,
            r'@:.c ${AppLocale.en.translations.a} ${AppLocale.en.translations.hi} ${AppLocale.en.translations.wow}. ${AppLocale.en.translations.nice.cool}');
        expect(node.params, <String>{});
      });
    });

    group(StringInterpolation.braces, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node = TextNode.test(test, StringInterpolation.braces);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = 'I have one argument named {apple}.';
        final node = TextNode.test(test, StringInterpolation.braces);
        expect(node.content, 'I have one argument named \$apple.');
        expect(node.params, {'apple'});
      });

      test('one argument without space', () {
        final test = 'I have one argument named{apple}.';
        final node = TextNode.test(test, StringInterpolation.braces);
        expect(node.content, 'I have one argument named\$apple.');
        expect(node.params, {'apple'});
      });

      test('one argument followed by underscore', () {
        final test = 'This string has one argument named {tom}_';
        final node = TextNode.test(test, StringInterpolation.braces);
        expect(node.content, 'This string has one argument named \${tom}_');
        expect(node.params, {'tom'});
      });

      test('one argument followed by number', () {
        final test = 'This string has one argument named {tom}7';
        final node = TextNode.test(test, StringInterpolation.braces);
        expect(node.content, 'This string has one argument named \${tom}7');
        expect(node.params, {'tom'});
      });

      test('one argument with fake arguments', () {
        final test =
            r'$ I have one argument named {apple} but this is $fake. \$ $';
        final node = TextNode.test(test, StringInterpolation.braces);
        expect(node.content,
            r'\$ I have one argument named $apple but this is \$fake. \$ \$');
        expect(node.params, {'apple'});
      });

      test('one escaped argument escaped', () {
        final test = 'I have one argument named \\{apple}.';
        final node = TextNode.test(test, StringInterpolation.braces);
        expect(node.content, 'I have one argument named {apple}.');
        expect(node.params, <String>{});
      });

      test('one argument with link', () {
        final test = '{apple} is linked to @:wow!';
        final node = TextNode.test(test, StringInterpolation.braces);
        expect(node.content,
            '\$apple is linked to \${AppLocale.en.translations.wow}!');
        expect(node.params, {'apple'});
      });

      test('with case', () {
        final test = r'Nice {cool_hi} {wow} {yes}a {no_yes}';
        final node =
            TextNode.test(test, StringInterpolation.braces, CaseStyle.camel);
        expect(node.content, r'Nice $coolHi $wow ${yes}a $noYes');
        expect(node.params, {'coolHi', 'wow', 'yes', 'noYes'});
      });
    });

    group(StringInterpolation.doubleBraces, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node = TextNode.test(test, StringInterpolation.doubleBraces);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = 'I have one argument named {{apple}}.';
        final node = TextNode.test(test, StringInterpolation.doubleBraces);
        expect(node.content, 'I have one argument named \$apple.');
        expect(node.params, {'apple'});
      });

      test('one argument followed by underscore', () {
        final test = 'This string has one argument named {{tom}}_';
        final node = TextNode.test(test, StringInterpolation.doubleBraces);
        expect(node.content, 'This string has one argument named \${tom}_');
        expect(node.params, {'tom'});
      });

      test('one argument followed by number', () {
        final test = 'This string has one argument named {{tom}}7';
        final node = TextNode.test(test, StringInterpolation.doubleBraces);
        expect(node.content, 'This string has one argument named \${tom}7');
        expect(node.params, {'tom'});
      });

      test('one fake argument', () {
        final test = 'I have one argument named \\{apple}.';
        final node = TextNode.test(test, StringInterpolation.doubleBraces);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one escaped argument', () {
        final test = 'I have one argument named \\{{apple}}.';
        final node = TextNode.test(test, StringInterpolation.doubleBraces);
        expect(node.content, 'I have one argument named {{apple}}.');
        expect(node.params, <String>{});
      });

      test('with case', () {
        final test = r'Nice {{cool_hi}} {{wow}} {{yes}}a {{no_yes}}';
        final node = TextNode.test(
            test, StringInterpolation.doubleBraces, CaseStyle.camel);
        expect(node.content, r'Nice $coolHi $wow ${yes}a $noYes');
        expect(node.params, {'coolHi', 'wow', 'yes', 'noYes'});
      });
    });
  });
}
