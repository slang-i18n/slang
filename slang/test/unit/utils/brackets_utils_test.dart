import 'package:slang/src/builder/utils/brackets_utils.dart';
import 'package:test/test.dart';

void main() {
  group('findTopLevelBrackets', () {
    test('no brackets', () {
      expect(BracketsUtils.findTopLevelBrackets('hello world'), []);
    });

    test('one full bracket', () {
      final result = BracketsUtils.findTopLevelBrackets('{hello world}');
      expect(result.first.substring(), '{hello world}');
      expect(result.first.replaceWith('apple'), 'apple');
    });

    test('one middle bracket', () {
      final result =
          BracketsUtils.findTopLevelBrackets('hello {hello world} nice');
      expect(result.first.substring(), '{hello world}');
      expect(result.first.replaceWith('apple'), 'hello apple nice');
    });

    test('one fake closing bracket', () {
      final result =
          BracketsUtils.findTopLevelBrackets('hel}lo {hello world} nice');
      expect(result.first.substring(), '{hello world}');
      expect(result.first.replaceWith('apple'), 'hel}lo apple nice');
    });

    test('never closing bracket', () {
      final result =
          BracketsUtils.findTopLevelBrackets('hel}lo {hello world nice');
      expect(result, []);
    });

    test('two brackets', () {
      final result =
          BracketsUtils.findTopLevelBrackets('hello {apple} wow {banana}');
      expect(result[0].substring(), '{apple}');
      expect(result[1].substring(), '{banana}');
    });

    test('two brackets with fake brackets', () {
      final result =
          BracketsUtils.findTopLevelBrackets('hel}lo {apple} wo}w {banana}');
      expect(result[0].substring(), '{apple}');
      expect(result[1].substring(), '{banana}');
    });

    test('nested bracket', () {
      final result =
          BracketsUtils.findTopLevelBrackets('hello {hello {apple}} world');
      expect(result.first.substring(), '{hello {apple}}');
    });

    test('two nested brackets', () {
      final result = BracketsUtils.findTopLevelBrackets(
          'hello {hello {apple}} world yes {of {course{you}are}}!');
      expect(result[0].substring(), '{hello {apple}}');
      expect(result[1].substring(), '{of {course{you}are}}');
      expect(result[0].replaceWith('hello world'),
          'hello hello world world yes {of {course{you}are}}!');
      expect(result[1].replaceWith('hello world'),
          'hello {hello {apple}} world yes hello world!');
    });
  });
}
