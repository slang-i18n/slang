import 'package:slang/builder/model/enums.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('capitalize', () {
    test('empty', () {
      expect(''.capitalize(), '');
    });

    test('1 character', () {
      expect('e'.capitalize(), 'E');
    });

    test('more characters', () {
      expect('heLLo'.capitalize(), 'Hello');
    });
  });

  group('toCase', () {
    test('no transformation', () {
      expect('hello_worldCool'.toCase(null), 'hello_worldCool');
    });

    test('camel to camel', () {
      expect('helloWorldCool'.toCase(CaseStyle.camel), 'helloWorldCool');
    });

    test('camel to snake', () {
      expect('helloWorldCool'.toCase(CaseStyle.snake), 'hello_world_cool');
    });

    test('snake to snake', () {
      expect('hello_world_cool'.toCase(CaseStyle.snake), 'hello_world_cool');
    });

    test('snake to camel', () {
      expect('hello_world_cool'.toCase(CaseStyle.camel), 'helloWorldCool');
    });

    test('pascal to camel', () {
      expect('HelloWorldCool'.toCase(CaseStyle.camel), 'helloWorldCool');
    });

    test('camel to pascal', () {
      expect('helloWorldCool'.toCase(CaseStyle.pascal), 'HelloWorldCool');
    });

    test('snake to pascal', () {
      expect('hello_world_cool'.toCase(CaseStyle.pascal), 'HelloWorldCool');
    });

    test('mix to snake', () {
      expect('hello_worldCool-lol-23-end'.toCase(CaseStyle.snake),
          'hello_world_cool_lol_23_end');
    });
  });
}
