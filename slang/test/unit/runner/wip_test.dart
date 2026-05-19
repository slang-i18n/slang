import 'package:slang/overrides.dart';
import 'package:slang/src/runner/wip.dart';
import 'package:test/test.dart';

void main() {
  final baseCasingTree = CasingNodeRoot.fromMap({
    'pages': {
      'loginPage': {
        'title': '',
      },
    },
  });

  group('WipInvocationCollection.findInString', () {
    WipInvocationCollection f(String source) {
      return WipInvocationCollection.findInString(
        translateVar: 't',
        source: source,
        interpolation: StringInterpolation.braces,
        baseCasingTree: baseCasingTree,
      );
    }

    test('Should find nothing', () {
      final result = f(r'''
final a = 1;
final t = 2;
final c = 3; // t.$wip.someMethod('test');
final d = 4; /* t.$wip.anotherMethod('test'); */
/*
t.$wip.multilineMethod('test');
*/
''');

      expect(result.map, {});
      expect(result.list, []);
      expect(result.correctedPaths, {});
    });

    test('Should find basic invocation', () {
      final result = f(r"final greeting = t.$wip.my.path('Hello, World!');");

      expect(result.map, {
        'my': {
          'path': 'Hello, World!',
        },
      });
      expect(result.list.length, 1);
      expect(result.list[0].original, r"t.$wip.my.path('Hello, World!')");
      expect(result.list[0].path, 'my.path');
      expect(result.list[0].sanitizedValue, 'Hello, World!');
      expect(result.list[0].parameterMap, {});
      expect(result.correctedPaths, {});
    });

    test('Should correct casing', () {
      final result =
          f(r"final title = t.$wip.pages.loginpage.subTitle('Welcome');");

      expect(result.map, {
        'pages': {
          'loginPage': {
            'subTitle': 'Welcome',
          },
        },
      });
      expect(result.list.length, 1);
      expect(result.list[0].original,
          r"t.$wip.pages.loginpage.subTitle('Welcome')");
      expect(result.list[0].path, 'pages.loginPage.subTitle');
      expect(result.list[0].sanitizedValue, 'Welcome');
      expect(result.list[0].parameterMap, {});
      expect(result.correctedPaths, {
        'pages.loginPage.subTitle': CasingCorrection(
          original: 'pages.loginpage.subTitle',
          note: 'BASE',
        ),
      });
    });

    test('Should decide on majority casing', () {
      final result = f(r"""
final a = t.$wip.pages.startPage.a('A');
final b = t.$wip.pages.startpage.b('B')
final c = t.$wip.pages.startPage.c('C')""");

      expect(result.map, {
        'pages': {
          'startPage': {
            'a': 'A',
            'b': 'B',
            'c': 'C',
          },
        },
      });
      expect(result.list.length, 3);
      expect(result.correctedPaths, {
        'pages.startPage.b': CasingCorrection(
          original: 'pages.startpage.b',
          note: '67%',
        ),
      });
    });

    test('Should decide on majority casing (nested)', () {
      final baseCasingTree = CasingNodeRoot.fromMap({});

      final result = WipInvocationCollection.findInString(
        translateVar: 't',
        source: r"""
final a = t.$wip.myGroup.subSection.a('A');
final b = t.$wip.mygroup.subSection.b('B');
final c = t.$wip.myGroup.subSection.c('C');
final d = t.$wip.myGroup.subsection.d('D');
final e = t.$wip.myGroup.subsection.e('E');""",
        interpolation: StringInterpolation.dart,
        baseCasingTree: baseCasingTree,
      );

      expect(result.map, {
        'myGroup': {
          'subSection': {
            'a': 'A',
            'b': 'B',
            'c': 'C',
            'd': 'D',
            'e': 'E',
          },
        },
      });
      expect(result.list.length, 5);

      final confidence = ((((4 / 5) + (3 / 5)) / 2) * 100).round();
      expect(confidence, 70);

      expect(result.correctedPaths, {
        'myGroup.subSection.b': CasingCorrection(
          original: 'mygroup.subSection.b',
          note: '$confidence%',
        ),
        'myGroup.subSection.d': CasingCorrection(
          original: 'myGroup.subsection.d',
          note: '$confidence%',
        ),
        'myGroup.subSection.e': CasingCorrection(
          original: 'myGroup.subsection.e',
          note: '$confidence%',
        ),
      });
    });

    test('Should find invocation within brackets', () {
      final result = f(r"f(t.$wip.a('b'));");

      expect(result.map, {
        'a': 'b',
      });
      expect(result.list.length, 1);
      expect(
        result.list[0].original,
        r"""t.$wip.a('b')""",
      );
      expect(result.list[0].path, 'a');
      expect(result.list[0].sanitizedValue, 'b');
      expect(result.list[0].parameterMap, {});
      expect(result.correctedPaths, {});
    });

    test('Should find invocation within nested brackets', () {
      final result = f(r"""
f(
  g(t.$wip.a('b')),
);
""");

      expect(result.map, {
        'a': 'b',
      });
      expect(result.list.length, 1);
      expect(
        result.list[0].original,
        r"""t.$wip.a('b')""",
      );
      expect(result.list[0].path, 'a');
      expect(result.list[0].sanitizedValue, 'b');
      expect(result.list[0].parameterMap, {});
      expect(result.correctedPaths, {});
    });

    test('Should find invocation with interpolation', () {
      final result = f(r'''
final greeting = t.$wip.welcome.message('Hello, $name!');
''');

      expect(result.map, {
        'welcome': {
          'message': 'Hello, {name}!',
        },
      });
      expect(result.list.length, 1);
      expect(
          result.list[0].original, r"t.$wip.welcome.message('Hello, $name!')");
      expect(result.list[0].path, 'welcome.message');
      expect(result.list[0].sanitizedValue, 'Hello, {name}!');
      expect(result.list[0].parameterMap, {'name': 'name'});
      expect(result.correctedPaths, {});
    });

    test('Should sanitize parameters', () {
      final result = f(r'''
t.$wip.greet('Hi, $name, ${ name }, $_name, ${nested.name}, ${nested._name}, ${nested.otherName1}');
''');

      expect(result.map, {
        'greet':
            'Hi, {name}, {name}, {name2}, {nestedName}, {nestedName2}, {otherName1}',
      });
      expect(result.list.length, 1);
      expect(result.list[0].original,
          r"t.$wip.greet('Hi, $name, ${ name }, $_name, ${nested.name}, ${nested._name}, ${nested.otherName1}')");
      expect(result.list[0].path, 'greet');
      expect(result.list[0].sanitizedValue,
          'Hi, {name}, {name}, {name2}, {nestedName}, {nestedName2}, {otherName1}');
      expect(
        result.list[0].parameterMap,
        {
          'name': 'name',
          'name2': '_name',
          'nestedName': 'nested.name',
          'nestedName2': 'nested._name',
          'otherName1': 'nested.otherName1',
        },
      );
      expect(result.correctedPaths, {});
    });

    test('Should respect numbers in path', () {
      final result = f(r'''
t.$wip.section1.item2('Value with $param');
''');

      expect(result.map, {
        'section1': {
          'item2': 'Value with {param}',
        },
      });
      expect(result.list.length, 1);
      expect(result.list[0].original,
          r"t.$wip.section1.item2('Value with $param')");
      expect(result.list[0].path, 'section1.item2');
      expect(result.list[0].sanitizedValue, 'Value with {param}');
      expect(result.list[0].parameterMap, {'param': 'param'});
      expect(result.correctedPaths, {});
    });

    test('Should detect with spaces in argument', () {
      final result = f(r'''
t.$wip.testMethod(
  'Value with spaces and $param inside',
);
''');

      expect(result.map, {
        'testMethod': 'Value with spaces and {param} inside',
      });
      expect(result.list.length, 1);
      expect(result.list[0].original, r"""
t.$wip.testMethod(
  'Value with spaces and $param inside',
)""");
      expect(result.list[0].path, 'testMethod');
      expect(result.list[0].sanitizedValue,
          'Value with spaces and {param} inside');
      expect(result.list[0].parameterMap, {'param': 'param'});
      expect(result.correctedPaths, {});
    });

    test('Should handle a function as argument', () {
      final result = f(r'''
t.$wip.complexMethod(
  someFunction('test', param: $value),
);
''');

      expect(result.map, {
        'complexMethod': '{someFunction}',
      });
      expect(result.list.length, 1);
      expect(result.list[0].original, r"""
t.$wip.complexMethod(
  someFunction('test', param: $value),
)""");
      expect(result.list[0].path, 'complexMethod');
      expect(result.list[0].sanitizedValue, '{someFunction}');
      expect(result.list[0].parameterMap, {
        'someFunction': r'''someFunction('test', param: $value),''',
      });
      expect(result.correctedPaths, {});
    });

    test('Should handle a variable as argument', () {
      final result = f(r'''
t.$wip.variableMethod(
  myVariable,
);
''');
      expect(result.map, {
        'variableMethod': '{myVariable}',
      });
      expect(result.list.length, 1);
      expect(result.list[0].original, r'''
t.$wip.variableMethod(
  myVariable,
)''');
      expect(result.list[0].path, 'variableMethod');
      expect(result.list[0].sanitizedValue, '{myVariable}');
      expect(result.list[0].parameterMap, {
        'myVariable': r'myVariable,',
      });
      expect(result.correctedPaths, {});
    });
  });
}
