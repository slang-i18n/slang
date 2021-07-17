import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/string_extensions.dart';
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
      expect('helloWorldCool'.toCase(KeyCase.camel), 'helloWorldCool');
    });

    test('camel to snake', () {
      expect('helloWorldCool'.toCase(KeyCase.snake), 'hello_world_cool');
    });

    test('snake to snake', () {
      expect('hello_world_cool'.toCase(KeyCase.snake), 'hello_world_cool');
    });

    test('snake to camel', () {
      expect('hello_world_cool'.toCase(KeyCase.camel), 'helloWorldCool');
    });

    test('pascal to camel', () {
      expect('HelloWorldCool'.toCase(KeyCase.camel), 'helloWorldCool');
    });

    test('camel to pascal', () {
      expect('helloWorldCool'.toCase(KeyCase.pascal), 'HelloWorldCool');
    });

    test('snake to pascal', () {
      expect('hello_world_cool'.toCase(KeyCase.pascal), 'HelloWorldCool');
    });

    test('mix to snake', () {
      expect(
          'hello_worldCool-lol-23-end'.toCase(KeyCase.snake), 'hello_world_cool_lol_23_end');
    });
  });

  group('toEnumConstant', () {
    test('en', () {
      expect('en'.toEnumConstant(), 'en');
    });

    test('en-EN', () {
      expect('en-EN'.toEnumConstant(), 'enEn');
    });

    test('en-EN-EN', () {
      expect('en-EN-EN'.toEnumConstant(), 'enEnEn');
    });

    test('en-En-En', () {
      expect('en-En-En'.toEnumConstant(), 'enEnEn');
    });
  });
}
