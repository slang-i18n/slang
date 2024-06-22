import 'package:slang/src/builder/utils/reflection_utils.dart';
import 'package:test/test.dart';

void main() {
  group('getFunctionParameters', () {
    test('Should parse empty function', () {
      final result = getFunctionParameters(() {});
      expect(result, isEmpty);
    });

    test('Should parse function one parameter', () {
      final result = getFunctionParameters(({required int myArg}) {});
      expect(result, {'myArg'});
    });

    test('Should parse function two parameters', () {
      final result = getFunctionParameters(
        ({required int myArg, required String myArg2}) {},
      );
      expect(result, {'myArg', 'myArg2'});
    });

    test('Should parse function with generic type', () {
      final result = getFunctionParameters(({required List<int> myArg}) {});
      expect(result, {'myArg'});
    });
  });
}
