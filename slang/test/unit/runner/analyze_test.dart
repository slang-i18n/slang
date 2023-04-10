import 'package:slang/runner/analyze.dart';
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
  });
}
