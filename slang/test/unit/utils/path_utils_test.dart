import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/utils/path_utils.dart';
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

  group('findDirectoryLocale', () {
    f(String filePath, [String? inputDirectory]) =>
        PathUtils.findDirectoryLocale(
          filePath: filePath,
          inputDirectory: inputDirectory,
        );

    test('empty', () {
      expect(f(''), null);
    });

    test('file only', () {
      expect(f('hello.json'), null);
    });

    test('locale in first directory', () {
      expect(f('/de/world/haha/cool.json'), null);
    });

    test('locale in last directory', () {
      expect(f('/test/world/de/fr/cool.json'), I18nLocale(language: 'fr'));
    });

    test('locale in first directory after inputDirectory', () {
      expect(
        f('/de/world/es/haha/fr/cool.json', '/de/world'),
        I18nLocale(language: 'es'),
      );
    });
  });
}
