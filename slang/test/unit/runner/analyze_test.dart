import 'package:slang/src/runner/analyze.dart';
import 'package:test/test.dart';

import '../../util/mocks/fake_file.dart';

void main() {
  group('loadSourceCode', () {
    test('join multiple files', () {
      final files = [
        FakeFile('A'),
        FakeFile('B'),
        FakeFile('C'),
      ];

      final result = loadSourceCode(files);

      expect(result, 'ABC');
    });

    test('should ignore spaces', () {
      final files = [
        FakeFile('A\nB C\tD'),
        FakeFile('E\r\nF  G'),
        FakeFile('H;'),
      ];

      final result = loadSourceCode(files);

      expect(result, 'ABCDEFGH;');
    });

    test('should ignore inline comments', () {
      final files = [
        FakeFile('A // B\nC'),
        FakeFile('D /* E */ F'),
        FakeFile('G'),
      ];

      final result = loadSourceCode(files);

      expect(result, 'ACDFG');
    });

    test('should ignore block comments', () {
      final files = [
        FakeFile('A /* B\nC */ D'),
        FakeFile('E // F'),
        FakeFile('G //'),
      ];

      final result = loadSourceCode(files);

      expect(result, 'ADEG');
    });
  });
}
