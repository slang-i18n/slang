import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/node.dart';
import 'package:test/test.dart';

import '../../util/text_node_builder.dart';

void main() {
  group(ListNode, () {
    final interpolation = StringInterpolation.braces;

    test('Plain strings', () {
      final node = ListNode(
        path: '',
        rawPath: '',
        comment: null,
        modifiers: {},
        entries: [
          textNode('Hello', interpolation),
          textNode('Hi', interpolation),
        ],
      );

      expect(node.genericType, 'String');
    });

    test('Parameterized strings', () {
      final node = ListNode(
        path: '',
        rawPath: '',
        comment: null,
        modifiers: {},
        entries: [
          textNode('Hello', interpolation),
          textNode('Hi {name}', interpolation),
        ],
      );

      expect(node.genericType, 'dynamic');
    });

    test('Nested list', () {
      final node = ListNode(
        path: '',
        rawPath: '',
        comment: null,
        modifiers: {},
        entries: [
          ListNode(
            path: '',
            rawPath: '',
            comment: null,
            modifiers: {},
            entries: [
              textNode('Hello', interpolation),
              textNode('Hi {name}', interpolation),
            ],
          ),
          ListNode(
            path: '',
            rawPath: '',
            comment: null,
            modifiers: {},
            entries: [
              textNode('Hello', interpolation),
              textNode('Hi {name}', interpolation),
            ],
          ),
        ],
      );

      expect(node.genericType, 'List<dynamic>');
    });

    test('Deeper Nested list', () {
      final node = ListNode(
        path: '',
        rawPath: '',
        comment: null,
        modifiers: {},
        entries: [
          ListNode(
            path: '',
            rawPath: '',
            comment: null,
            modifiers: {},
            entries: [
              ListNode(
                path: '',
                rawPath: '',
                comment: null,
                modifiers: {},
                entries: [
                  textNode('Hello', interpolation),
                  textNode('Hi', interpolation),
                ],
              ),
            ],
          ),
          ListNode(
            path: '',
            rawPath: '',
            comment: null,
            modifiers: {},
            entries: [
              ListNode(
                path: '',
                rawPath: '',
                comment: null,
                modifiers: {},
                entries: [
                  textNode('Hello', interpolation),
                  textNode('Hi', interpolation),
                ],
              ),
              ListNode(
                path: '',
                rawPath: '',
                comment: null,
                modifiers: {},
                entries: [
                  textNode('Hello', interpolation),
                  textNode('Hi', interpolation),
                ],
              ),
            ],
          ),
        ],
      );

      expect(node.genericType, 'List<List<String>>');
    });

    test('Class', () {
      final node = ListNode(
        path: '',
        rawPath: '',
        comment: null,
        modifiers: {},
        entries: [
          ObjectNode(
            path: '',
            rawPath: '',
            comment: null,
            modifiers: {},
            entries: {
              'key0': textNode('Hi', interpolation),
            },
            isMap: false,
          ),
          ObjectNode(
            path: '',
            rawPath: '',
            comment: null,
            modifiers: {},
            entries: {
              'key0': textNode('Hi', interpolation),
            },
            isMap: false,
          ),
        ],
      );

      expect(node.genericType, 'dynamic');
    });

    test('Map', () {
      final node = ListNode(
        path: '',
        rawPath: '',
        comment: null,
        modifiers: {},
        entries: [
          ObjectNode(
            path: '',
            rawPath: '',
            comment: null,
            modifiers: {},
            entries: {
              'key0': textNode('Hi', interpolation),
            },
            isMap: true,
          ),
          ObjectNode(
            path: '',
            rawPath: '',
            comment: null,
            modifiers: {},
            entries: {
              'key0': textNode('Hi', interpolation),
            },
            isMap: true,
          ),
        ],
      );

      expect(node.genericType, 'Map<String, String>');
    });
  });

  group(StringTextNode, () {
    group(StringInterpolation.dart, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node = textNode(test, StringInterpolation.dart);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = r'I have one argument named $apple.';
        final node = textNode(test, StringInterpolation.dart);
        expect(node.content, r'I have one argument named ${apple}.');
        expect(node.params, {'apple'});
      });

      test('one duplicate argument', () {
        final test = r'This string has one $argument and $argument.';
        final node = textNode(test, StringInterpolation.dart);
        expect(
            node.content, r'This string has one ${argument} and ${argument}.');
        expect(node.params, {'argument'});
      });

      test('one argument at the beginning', () {
        final test = r'${test} at the beginning.';
        final node = textNode(test, StringInterpolation.dart);
        expect(node.content, test);
        expect(node.params, {'test'});
      });

      test('one escaped argument', () {
        final test = r'I have one argument named \$apple.';
        final node = textNode(test, StringInterpolation.dart);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument with link', () {
        final test = r'$apple is linked to @:wow!';
        final node = textNode(test, StringInterpolation.dart);
        expect(node.content, r'${apple} is linked to ${_root.wow}!');
        expect(node.params, {'apple'});
      });

      test('one argument and single dollars', () {
        final test =
            r'$ I have \$ one argument named $apple but also a $ and a $';
        final node = textNode(test, StringInterpolation.dart);
        expect(node.content,
            r'\$ I have \$ one argument named ${apple} but also a \$ and a \$');
        expect(node.params, {'apple'});
      });

      test('with case', () {
        final test = r'Nice $cool_hi $wow ${yes} ${no_yes} @:hello_world.yes';
        final node = textNode(
          test,
          StringInterpolation.dart,
          paramCase: CaseStyle.camel,
        );
        expect(node.content,
            r'Nice ${coolHi} ${wow} ${yes} ${noYes} ${_root.hello_world.yes}');
        expect(node.params, {'coolHi', 'wow', 'yes', 'noYes'});
      });

      test('with links', () {
        final test = r'@:.c @:a @:hi @:wow. @:nice.cool';
        final node = textNode(test, StringInterpolation.dart);
        expect(node.content,
            r'@:.c ${_root.a} ${_root.hi} ${_root.wow}. ${_root.nice.cool}');
        expect(node.params, <String>{});
      });

      test('with escaped links', () {
        final test = r'@:.c@:{a}@:{hi}@:wow. @:{nice.cool} @:nice.cool';
        final node = textNode(test, StringInterpolation.dart);
        expect(node.content,
            r'@:.c${_root.a}${_root.hi}${_root.wow}. ${_root.nice.cool} ${_root.nice.cool}');
        expect(node.params, <String>{});
      });

      test('with links and params', () {
        final test = r'@:a @:b';
        final node = textNode(test, StringInterpolation.dart, linkParamMap: {
          'a': {},
          'b': {'c', 'd'},
        });
        expect(node.content, r'${_root.a} ${_root.b(c: c, d: d)}');
        expect(node.params, <String>{'c', 'd'});
      });
    });

    group(StringInterpolation.braces, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node = textNode(test, StringInterpolation.braces);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = 'I have one argument named {apple}.';
        final node = textNode(test, StringInterpolation.braces);
        expect(node.content, 'I have one argument named \${apple}.');
        expect(node.params, {'apple'});
      });

      test('one argument without space', () {
        final test = 'I have one argument named{apple}.';
        final node = textNode(test, StringInterpolation.braces);
        expect(node.content, 'I have one argument named\${apple}.');
        expect(node.params, {'apple'});
      });

      test('one argument followed by underscore', () {
        final test = 'This string has one argument named {tom}_';
        final node = textNode(test, StringInterpolation.braces);
        expect(node.content, 'This string has one argument named \${tom}_');
        expect(node.params, {'tom'});
      });

      test('one argument followed by number', () {
        final test = 'This string has one argument named {tom}7';
        final node = textNode(test, StringInterpolation.braces);
        expect(node.content, 'This string has one argument named \${tom}7');
        expect(node.params, {'tom'});
      });

      test('one argument with fake arguments', () {
        final test =
            r'$ I have one argument named {apple} but this is $fake. \$ $';
        final node = textNode(test, StringInterpolation.braces);
        expect(node.content,
            r'\$ I have one argument named ${apple} but this is \$fake. \$ \$');
        expect(node.params, {'apple'});
      });

      test('one escaped argument escaped', () {
        final test = 'I have one argument named \\{apple}.';
        final node = textNode(test, StringInterpolation.braces);
        expect(node.content, 'I have one argument named {apple}.');
        expect(node.params, <String>{});
      });

      test('one argument with link', () {
        final test = '{apple} is linked to @:wow!';
        final node = textNode(test, StringInterpolation.braces);
        expect(node.content, '\${apple} is linked to \${_root.wow}!');
        expect(node.params, {'apple'});
      });

      test('with case', () {
        final test = r'Nice {cool_hi} {wow} {yes}a {no_yes}';
        final node = textNode(
          test,
          StringInterpolation.braces,
          paramCase: CaseStyle.camel,
        );
        expect(node.content, r'Nice ${coolHi} ${wow} ${yes}a ${noYes}');
        expect(node.params, {'coolHi', 'wow', 'yes', 'noYes'});
      });
    });

    group(StringInterpolation.doubleBraces, () {
      test('no arguments', () {
        final test = 'No arguments';
        final node = textNode(test, StringInterpolation.doubleBraces);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one argument', () {
        final test = 'I have one argument named {{apple}}.';
        final node = textNode(test, StringInterpolation.doubleBraces);
        expect(node.content, 'I have one argument named \${apple}.');
        expect(node.params, {'apple'});
      });

      test('one argument followed by underscore', () {
        final test = 'This string has one argument named {{tom}}_';
        final node = textNode(test, StringInterpolation.doubleBraces);
        expect(node.content, 'This string has one argument named \${tom}_');
        expect(node.params, {'tom'});
      });

      test('one argument followed by number', () {
        final test = 'This string has one argument named {{tom}}7';
        final node = textNode(test, StringInterpolation.doubleBraces);
        expect(node.content, 'This string has one argument named \${tom}7');
        expect(node.params, {'tom'});
      });

      test('one fake argument', () {
        final test = 'I have one argument named \\{apple}.';
        final node = textNode(test, StringInterpolation.doubleBraces);
        expect(node.content, test);
        expect(node.params, <String>{});
      });

      test('one escaped argument', () {
        final test = 'I have one argument named \\{{apple}}.';
        final node = textNode(test, StringInterpolation.doubleBraces);
        expect(node.content, 'I have one argument named {{apple}}.');
        expect(node.params, <String>{});
      });

      test('with case', () {
        final test = r'Nice {{cool_hi}} {{wow}} {{yes}}a {{no_yes}}';
        final node = textNode(
          test,
          StringInterpolation.doubleBraces,
          paramCase: CaseStyle.camel,
        );
        expect(node.content, r'Nice ${coolHi} ${wow} ${yes}a ${noYes}');
        expect(node.params, {'coolHi', 'wow', 'yes', 'noYes'});
      });
    });
  });

  group(RichTextNode, () {
    test('no arguments', () {
      final test = 'No arguments';
      final node = richTextNode(test, StringInterpolation.dart);
      expect(node.spans.length, 1);
      expect(node.spans.first, isA<LiteralSpan>());
      expect((node.spans.first as LiteralSpan).literal, 'No arguments');
      expect(node.params, <String>{});
    });

    group(StringInterpolation.dart, () {
      test('one argument', () {
        final test = r'Hello $yey!';
        final node = richTextNode(test, StringInterpolation.dart);
        expect(node.spans.length, 3);
        expect((node.spans[0] as LiteralSpan).literal, 'Hello ');
        expect((node.spans[0] as LiteralSpan).isConstant, true);
        expect((node.spans[1] as VariableSpan).variableName, 'yey');
        expect((node.spans[2] as LiteralSpan).literal, '!');
        expect((node.spans[2] as LiteralSpan).isConstant, true);
        expect(node.params, {'yey'});
      });

      test('with default text', () {
        final test = r'Hello $yey ${underline(hi !>)}!';
        final node = richTextNode(test, StringInterpolation.dart);
        expect(node.spans.length, 5);
        expect((node.spans[0] as LiteralSpan).literal, 'Hello ');
        expect((node.spans[0] as LiteralSpan).isConstant, true);
        expect((node.spans[1] as VariableSpan).variableName, 'yey');
        expect((node.spans[2] as LiteralSpan).literal, ' ');
        expect((node.spans[2] as LiteralSpan).isConstant, true);
        expect((node.spans[3] as FunctionSpan).functionName, 'underline');
        expect((node.spans[3] as FunctionSpan).arg, 'hi !>');
        expect((node.spans[4] as LiteralSpan).literal, '!');
        expect((node.spans[4] as LiteralSpan).isConstant, true);
        expect(node.params, {'yey', 'underline'});
        expect(node.paramTypeMap, {
          'yey': 'InlineSpan',
          'underline': 'InlineSpanBuilder',
        });
      });

      test('with link', () {
        final test = r'Hello $yey @:myLink!';
        final node = richTextNode(test, StringInterpolation.dart);
        expect(node.spans.length, 3);
        expect((node.spans[0] as LiteralSpan).literal, 'Hello ');
        expect((node.spans[0] as LiteralSpan).isConstant, true);
        expect((node.spans[1] as VariableSpan).variableName, 'yey');
        expect((node.spans[2] as LiteralSpan).literal, ' \${_root.myLink}!');
        expect((node.spans[2] as LiteralSpan).isConstant, false);
        expect(node.links, {'myLink'});
        expect(node.params, {'yey'});
      });

      test('with links and params', () {
        final test = r'@:a $yey @:b';
        final node =
            richTextNode(test, StringInterpolation.dart, linkParamMap: {
          'a': {},
          'b': {'c', 'd'},
        });
        expect(node.spans.length, 3);
        expect((node.spans[0] as LiteralSpan).literal, r'${_root.a} ');
        expect((node.spans[0] as LiteralSpan).isConstant, false);
        expect((node.spans[1] as VariableSpan).variableName, 'yey');
        expect(
            (node.spans[2] as LiteralSpan).literal, r' ${_root.b(c: c, d: d)}');
        expect((node.spans[2] as LiteralSpan).isConstant, false);
        expect(node.links, {'a', 'b'});
        expect(node.params, <String>{'yey', 'c', 'd'});
      });
    });

    group(StringInterpolation.braces, () {
      test('one argument', () {
        final test = r'Hello {yey}!';
        final node = richTextNode(test, StringInterpolation.braces);
        expect(node.spans.length, 3);
        expect((node.spans[0] as LiteralSpan).literal, 'Hello ');
        expect((node.spans[0] as LiteralSpan).isConstant, true);
        expect((node.spans[1] as VariableSpan).variableName, 'yey');
        expect((node.spans[2] as LiteralSpan).literal, '!');
        expect((node.spans[2] as LiteralSpan).isConstant, true);
        expect(node.params, {'yey'});
      });

      test('one argument with default text', () {
        final test = r'Hello {yey(my text)}!';
        final node = richTextNode(test, StringInterpolation.braces);
        expect(node.spans.length, 3);
        expect((node.spans[0] as LiteralSpan).literal, 'Hello ');
        expect((node.spans[0] as LiteralSpan).isConstant, true);
        expect((node.spans[1] as FunctionSpan).functionName, 'yey');
        expect((node.spans[1] as FunctionSpan).arg, 'my text');
        expect((node.spans[2] as LiteralSpan).literal, '!');
        expect((node.spans[2] as LiteralSpan).isConstant, true);
        expect(node.params, {'yey'});
      });
    });

    group(StringInterpolation.doubleBraces, () {
      test('one argument', () {
        final test = r'Hello {{yey}}!';
        final node = richTextNode(test, StringInterpolation.doubleBraces);
        expect(node.spans.length, 3);
        expect((node.spans[0] as LiteralSpan).literal, 'Hello ');
        expect((node.spans[0] as LiteralSpan).isConstant, true);
        expect((node.spans[1] as VariableSpan).variableName, 'yey');
        expect((node.spans[2] as LiteralSpan).literal, '!');
        expect((node.spans[2] as LiteralSpan).isConstant, true);
        expect(node.params, {'yey'});
      });

      test('two arguments with default text and param case', () {
        final test = r'Hello {{myFirstSpan}}{{mySpan(Default Text)}}!';
        final node = richTextNode(
          test,
          StringInterpolation.doubleBraces,
          paramCase: CaseStyle.snake,
        );
        expect(node.spans.length, 4);
        expect((node.spans[0] as LiteralSpan).literal, 'Hello ');
        expect((node.spans[0] as LiteralSpan).isConstant, true);
        expect((node.spans[1] as VariableSpan).variableName, 'my_first_span');
        expect((node.spans[2] as FunctionSpan).functionName, 'my_span');
        expect((node.spans[2] as FunctionSpan).arg, 'Default Text');
        expect((node.spans[3] as LiteralSpan).literal, '!');
        expect((node.spans[3] as LiteralSpan).isConstant, true);
        expect(node.params, {'my_first_span', 'my_span'});
      });

      test('one argument with default text having special chars', () {
        final test = r'Hello {{yey(my -Text!>)}}!';
        final node = richTextNode(test, StringInterpolation.doubleBraces);
        expect(node.spans.length, 3);
        expect((node.spans[0] as LiteralSpan).literal, 'Hello ');
        expect((node.spans[0] as LiteralSpan).isConstant, true);
        expect((node.spans[1] as FunctionSpan).functionName, 'yey');
        expect((node.spans[1] as FunctionSpan).arg, 'my -Text!>');
        expect((node.spans[2] as LiteralSpan).literal, '!');
        expect((node.spans[2] as LiteralSpan).isConstant, true);
        expect(node.params, {'yey'});
      });

      test('one argument with default text having a link', () {
        final test = r'Hello {{yey(hello!@:linked.path)}}!';
        final node = richTextNode(test, StringInterpolation.doubleBraces);
        expect(node.spans.length, 3);
        expect((node.spans[0] as LiteralSpan).literal, 'Hello ');
        expect((node.spans[0] as LiteralSpan).isConstant, true);
        expect((node.spans[1] as FunctionSpan).functionName, 'yey');
        expect(
          (node.spans[1] as FunctionSpan).arg,
          'hello!\${_root.linked.path}',
        );
        expect((node.spans[2] as LiteralSpan).literal, '!');
        expect((node.spans[2] as LiteralSpan).isConstant, true);
        expect(node.params, {'yey'});
      });
    });
  });
}
