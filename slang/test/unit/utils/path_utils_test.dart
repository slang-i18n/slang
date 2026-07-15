import 'package:slang/src/builder/model/i18n_locale.dart';
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
      expect(
        f('/test/world/de/fr/cool.json'),
        DirectoryLocaleResult(
          locale: I18nLocale(language: 'fr'),
          localeSegmentIndex: 3,
          namespacePrefix: const [],
        ),
      );
    });

    test('locale in first directory after inputDirectory', () {
      expect(
        f('/de/world/es/cool.json', '/de/world'),
        DirectoryLocaleResult(
          locale: I18nLocale(language: 'es'),
          localeSegmentIndex: 2,
          namespacePrefix: const [],
        ),
      );
      expect(
        f('/de/world/es/haha/cool.json', '/de/world'),
        DirectoryLocaleResult(
          locale: I18nLocale(language: 'es'),
          localeSegmentIndex: 2,
          namespacePrefix: const ['haha'],
        ),
      );
      expect(
        f('/de/world/es/haha/fr/cool.json', '/de/world'),
        DirectoryLocaleResult(
          locale: I18nLocale(language: 'es'),
          localeSegmentIndex: 2,
          namespacePrefix: const ['haha', 'fr'],
        ),
      );
    });
  });

  group('BuildResultPaths.localePath', () {
    String f(String outputPath) => BuildResultPaths.localePath(
          outputPath: outputPath,
          locale: I18nLocale(language: 'en', country: 'US'),
        );

    test('default .g.dart extension', () {
      expect(f('lib/gen/strings.g.dart'), 'lib/gen/strings_en_US.g.dart');
    });

    test('preserves custom multi-part extension', () {
      expect(
        f('lib/gen/translations.slang.dart'),
        'lib/gen/translations_en_US.slang.dart',
      );
    });
  });

  group('BuildResultPaths.flatMapPath', () {
    String f(String outputPath) =>
        BuildResultPaths.flatMapPath(outputPath: outputPath);

    test('default .g.dart extension', () {
      expect(f('lib/gen/strings.g.dart'), 'lib/gen/strings_map.g.dart');
    });

    test('preserves custom multi-part extension', () {
      expect(
        f('lib/gen/translations.slang.dart'),
        'lib/gen/translations_map.slang.dart',
      );
    });
  });
}
