import 'package:slang/overrides.dart';
import 'package:slang/src/runner/wip.dart';
import 'package:test/test.dart';

void main() {
  group('WipInvocationCollection.findInString', () {
    WipInvocationCollection f(String source) {
      return WipInvocationCollection.findInString(
        translateVar: 't',
        source: source,
        interpolation: StringInterpolation.braces,
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
      expect(result.list[0].original, r"""t.$wip.testMethod(
  'Value with spaces and $param inside',
)""");
      expect(result.list[0].path, 'testMethod');
      expect(result.list[0].sanitizedValue,
          'Value with spaces and {param} inside');
      expect(result.list[0].parameterMap, {'param': 'param'});
    });
  });
}
