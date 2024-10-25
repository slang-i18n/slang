import 'package:slang/src/builder/utils/parameter_string_ext.dart';
import 'package:test/test.dart';

void main() {
  test('Should handle empty string', () {
    final result = ''.splitParameters();
    expect(result, isEmpty);
  });

  test('Should handle single parameter', () {
    final result = 'a'.splitParameters();
    expect(result, ['a']);
  });

  test('Should handle multiple parameters', () {
    final result = 'a, b, c'.splitParameters();
    expect(result, ['a', 'b', 'c']);
  });

  test('Should handle quoted parameters', () {
    final result = 'a, "b, c", d'.splitParameters();
    expect(result, ['a', '"b, c"', 'd']);
  });

  test('Should handle single quoted parameters', () {
    final result = "a, 'b, c', d".splitParameters();
    expect(result, ['a', "'b, c'", 'd']);
  });
}
