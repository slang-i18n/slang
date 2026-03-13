import 'package:slang/src/builder/builder/slang_file_collection_builder.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:test/test.dart';

PlainTranslationFile _file(String path) {
  return PlainTranslationFile(path: path, read: () => Future.value(''));
}

void main() {
  group('SlangFileCollectionBuilder.fromFileModel', () {
    test('should find locales', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: RawConfig.defaultConfig
            .copyWith(baseLocale: I18nLocale(language: 'de')),
        files: [
          _file('lib/i18n/en.i18n.json'),
          _file('lib/i18n/de.i18n.json'),
          _file('lib/i18n/fr_FR.i18n.json'),
          _file('lib/i18n/zh-CN.i18n.json'),
        ],
      );

      expect(model.files.length, 4);
      expect(model.files, [
        isTranslationFile(
          path: 'lib/i18n/de.i18n.json',
          locale: 'de',
          namespace: '_default',
        ),
        isTranslationFile(
          path: 'lib/i18n/en.i18n.json',
          locale: 'en',
          namespace: '_default',
        ),
        isTranslationFile(
          path: 'lib/i18n/fr_FR.i18n.json',
          locale: 'fr-FR',
          namespace: '_default',
        ),
        isTranslationFile(
          path: 'lib/i18n/zh-CN.i18n.json',
          locale: 'zh-CN',
          namespace: '_default',
        ),
      ]);
    });

    test('should find base locale (legacy)', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: RawConfig.defaultConfig
            .copyWith(baseLocale: I18nLocale(language: 'de')),
        files: [
          _file('lib/i18n/strings.i18n.json'),
        ],
        showWarning: false,
      );

      expect(model.files.length, 1);
      expect(
        model.files.first,
        isTranslationFile(
          path: 'lib/i18n/strings.i18n.json',
          locale: 'de',
          namespace: '_default',
        ),
      );
    });

    test('should find locale in file names (legacy)', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: RawConfig.defaultConfig
            .copyWith(baseLocale: I18nLocale(language: 'en')),
        files: [
          _file('lib/i18n/strings.i18n.json'),
          _file('lib/i18n/strings_de.i18n.json'),
          _file('lib/i18n/strings-fr-FR.i18n.json'),
        ],
        showWarning: false,
      );

      expect(model.files.length, 3);
      expect(model.files, [
        isTranslationFile(
          path: 'lib/i18n/strings_de.i18n.json',
          locale: 'de',
          namespace: '_default',
        ),
        isTranslationFile(
          path: 'lib/i18n/strings.i18n.json',
          locale: 'en',
          namespace: '_default',
        ),
        isTranslationFile(
          path: 'lib/i18n/strings-fr-FR.i18n.json',
          locale: 'fr-FR',
          namespace: '_default',
        ),
      ]);
    });

    test('should find base locale with namespace', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: RawConfig.defaultConfig.copyWith(
          baseLocale: I18nLocale(language: 'fr'),
          namespaces: true,
        ),
        files: [
          _file('lib/i18n/dialogs.i18n.json'),
        ],
        showWarning: false,
      );

      expect(model.files.length, 1);
      expect(
        model.files.first,
        isTranslationFile(
          path: 'lib/i18n/dialogs.i18n.json',
          locale: 'fr',
          namespace: 'dialogs',
        ),
      );
    });

    test('should find directory locale', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: RawConfig.defaultConfig.copyWith(
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
      expect(model.files, [
        isTranslationFile(
          path: 'lib/i18n/de/dialogs.i18n.json',
          locale: 'de',
          namespace: 'dialogs',
        ),
        isTranslationFile(
          path: 'lib/i18n/de/widgets.i18n.json',
          locale: 'de',
          namespace: 'widgets',
        ),
        isTranslationFile(
          path: 'lib/i18n/en/dialogs.i18n.json',
          locale: 'en',
          namespace: 'dialogs',
        ),
        isTranslationFile(
          path: 'lib/i18n/en/widgets.i18n.json',
          locale: 'en',
          namespace: 'widgets',
        ),
      ]);
    });

    test('should ignore underscore if directory locale is used', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: RawConfig.defaultConfig.copyWith(
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
      expect(model.files, [
        isTranslationFile(
          path: 'assets/fr/ab_cd.yaml',
          locale: 'fr',
          namespace: 'ab_cd',
        ),
        isTranslationFile(
          path: 'assets/fr/dialogs.yaml',
          locale: 'fr',
          namespace: 'dialogs',
        ),
      ]);
    });

    test('should detect namespace prefixes', () {
      final model = SlangFileCollectionBuilder.fromFileModel(
        config: RawConfig.defaultConfig.copyWith(
          baseLocale: I18nLocale(language: 'de'),
          namespaces: true,
          inputDirectory: 'lib/i18n/fr',
          inputFilePattern: '.json',
        ),
        files: [
          _file('lib/i18n/fr/en/login/dialogs.json'),
          _file('lib/i18n/fr/en/login/errors.json'),
          _file('lib/i18n/fr/en/home/dialogs.json'),
          _file('lib/i18n/fr/en/home/errors.json'),
          _file('lib/i18n/fr/en/_missing_translations.json'),
          _file('lib/i18n/fr/en/_missing_translations_en.json'),
          _file('lib/i18n/fr/en/_unused_translations.json'),
        ],
      );

      expect(model.files.length, 4);
      expect(model.files, [
        isTranslationFile(
          path: 'lib/i18n/fr/en/home/dialogs.json',
          locale: 'en',
          namespace: 'home.dialogs',
        ),
        isTranslationFile(
          path: 'lib/i18n/fr/en/home/errors.json',
          locale: 'en',
          namespace: 'home.errors',
        ),
        isTranslationFile(
          path: 'lib/i18n/fr/en/login/dialogs.json',
          locale: 'en',
          namespace: 'login.dialogs',
        ),
        isTranslationFile(
          path: 'lib/i18n/fr/en/login/errors.json',
          locale: 'en',
          namespace: 'login.errors',
        ),
      ]);
    });
  });
}

TypeMatcher<TranslationFile> isTranslationFile({
  required String path,
  required String locale,
  required String namespace,
}) {
  return isA<TranslationFile>()
      .having((f) => f.path, 'path', path)
      .having((f) => f.locale, 'locale', I18nLocale.fromString(locale))
      .having((f) => f.namespace, 'namespace', namespace);
}
