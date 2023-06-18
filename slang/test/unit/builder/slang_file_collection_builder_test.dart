import 'package:slang/builder/builder/slang_file_collection_builder.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/slang_file_collection.dart';
import 'package:test/test.dart';

import '../../util/config_utils.dart';

PlainTranslationFile _file(String path) {
  return PlainTranslationFile(path: path, read: () => Future.value(''));
}

void main() {
  group('SlangFileCollectionBuilder.fromFileModel', () {
    test('should find base locale', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: baseConfig.copyWith(baseLocale: I18nLocale(language: 'de')),
        files: [
          _file('lib/i18n/strings.i18n.json'),
        ],
      );

      expect(model.files.length, 1);
      expect(model.files.first.locale.language, 'de');
    });

    test('should find locale in file names', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: baseConfig.copyWith(baseLocale: I18nLocale(language: 'en')),
        files: [
          _file('lib/i18n/strings.i18n.json'),
          _file('lib/i18n/strings_de.i18n.json'),
          _file('lib/i18n/strings-fr-FR.i18n.json'),
        ],
      );

      expect(model.files.length, 3);
      expect(model.files[0].locale.language, 'en');
      expect(model.files[1].locale.language, 'de');
      expect(model.files[2].locale.language, 'fr');
      expect(model.files[2].locale.country, 'FR');
    });

    test('should find base locale with namespace', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: baseConfig.copyWith(
          baseLocale: I18nLocale(language: 'fr'),
          namespaces: true,
        ),
        files: [
          _file('lib/i18n/dialogs.i18n.json'),
        ],
      );

      expect(model.files.length, 1);
      expect(model.files.first.locale.language, 'fr');
      expect(model.files.first.namespace, 'dialogs');
    });

    test('should find directory locale', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: baseConfig.copyWith(
          baseLocale: I18nLocale(language: 'de'),
          namespaces: true,
        ),
        files: [
          _file('lib/i18n/de/dialogs.i18n.json'),
          _file('lib/i18n/de/widgets.i18n.json'),
          _file('lib/i18n/en/dialogs.i18n.json'),
          _file('lib/i18n/en/widgets.i18n.json'),
        ],
      );

      expect(model.files.length, 4);
      expect(model.files[0].locale.language, 'de');
      expect(model.files[0].namespace, 'dialogs');
      expect(model.files[1].locale.language, 'de');
      expect(model.files[1].namespace, 'widgets');
      expect(model.files[2].locale.language, 'en');
      expect(model.files[2].namespace, 'dialogs');
      expect(model.files[3].locale.language, 'en');
      expect(model.files[3].namespace, 'widgets');
    });

    test('should ignore underscore if directory locale is used', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: baseConfig.copyWith(
          baseLocale: I18nLocale(language: 'de'),
          inputFilePattern: '.yaml',
          namespaces: true,
        ),
        files: [
          _file('assets/fr/dialogs.yaml'),
          _file('assets/fr/ab_cd.yaml'),
        ],
      );

      expect(model.files.length, 2);
      expect(model.files[0].locale.language, 'fr');
      expect(model.files[0].namespace, 'dialogs');
      expect(model.files[1].locale.language, 'fr');
      expect(model.files[1].namespace, 'ab_cd');
    });
  });
}
