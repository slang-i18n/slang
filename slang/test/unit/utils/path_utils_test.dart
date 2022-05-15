import 'package:slang/builder/utils/path_utils.dart';
import 'package:test/test.dart';

void main() {
  group('getParentDirectory', () {
    final f = PathUtils.getParentDirectory;

    test('root file', () {
      expect(f('hello.json'), null);
    });

    test('normal file', () {
      expect(f('wow/nice/yeah/hello.json'), 'yeah');
    });

    test('backslash path', () {
      expect(f('wow\\nice\\yeah\\hello.json'), 'yeah');
    });
  });
}
