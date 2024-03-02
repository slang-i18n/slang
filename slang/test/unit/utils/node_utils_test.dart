import 'package:slang/src/builder/utils/node_utils.dart';
import 'package:test/test.dart';

void main() {
  group('NodeUtils.parseModifiers', () {
    test('No modifiers returns an empty map', () {
      final result = NodeUtils.parseModifiers('greet');
      expect(result.path, 'greet');
      expect(result.modifiers, {});
    });

    test('Single key-value modifier returns a map with one entry', () {
      final result = NodeUtils.parseModifiers('greet(param=gender)');
      expect(result.path, 'greet');
      expect(result.modifiers, {'param': 'gender'});
    });

    test('Single key-only modifier returns a map with one entry', () {
      final result = NodeUtils.parseModifiers('greet(rich)');
      expect(result.path, 'greet');
      expect(result.modifiers, {'rich': 'rich'});
    });

    test('Multiple modifiers return a map with multiple entries', () {
      final result = NodeUtils.parseModifiers('greet(param=gender, rich)');
      expect(result.path, 'greet');
      expect(result.modifiers, {'param': 'gender', 'rich': 'rich'});
    });

    test('Extra spaces are trimmed', () {
      final result = NodeUtils.parseModifiers('greet( param = gender , rich )');
      expect(result.path, 'greet');
      expect(result.modifiers, {'param': 'gender', 'rich': 'rich'});
    });
  });

  group('NodeUtils.serializeModifiers', () {
    test('Empty map returns the key', () {
      final result = NodeUtils.serializeModifiers('greet', {});
      expect(result, 'greet');
    });

    test('Single key-value modifier returns a serialized string', () {
      final result = NodeUtils.serializeModifiers(
        'greet',
        {'param': 'gender'},
      );
      expect(result, 'greet(param=gender)');
    });

    test('Single key-only modifier returns a serialized string', () {
      final result = NodeUtils.serializeModifiers(
        'greet',
        {'rich': 'rich'},
      );
      expect(result, 'greet(rich)');
    });

    test('Multiple modifiers return a serialized string', () {
      final result = NodeUtils.serializeModifiers(
        'greet',
        {'param': 'gender', 'rich': 'rich'},
      );
      expect(result, 'greet(param=gender, rich)');
    });
  });

  group('NodeUtils.addModifier', () {
    test('Adds a modifier to a key without modifiers', () {
      final result = NodeUtils.addModifier(
        original: 'greet',
        modifierKey: 'param',
        modifierValue: 'gender',
      );
      expect(result, 'greet(param=gender)');
    });

    test('Adds a modifier to a key with existing modifiers', () {
      final result = NodeUtils.addModifier(
        original: 'greet(param=gender)',
        modifierKey: 'a',
        modifierValue: 'b',
      );
      expect(result, 'greet(param=gender, a=b)');
    });

    test('Adds a key-only modifier', () {
      final result = NodeUtils.addModifier(
        original: 'greet(param=gender)',
        modifierKey: 'rich',
      );
      expect(result, 'greet(param=gender, rich)');
    });
  });

  group('StringModifierExt.withoutModifiers', () {
    test('Returns the original string when no modifiers are present', () {
      final input = 'greet';
      expect(input.withoutModifiers, 'greet');
    });

    test('Removes modifiers from a string with key-value modifier', () {
      final input = 'greet(param=gender)';
      expect(input.withoutModifiers, 'greet');
    });

    test('Removes modifiers from a string with key-only modifier', () {
      final input = 'greet(rich)';
      expect(input.withoutModifiers, 'greet');
    });

    test('Removes modifiers from a string with multiple modifiers', () {
      final input = 'greet(param=gender, rich)';
      expect(input.withoutModifiers, 'greet');
    });
  });
}
