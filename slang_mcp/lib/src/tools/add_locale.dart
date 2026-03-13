// ignore: implementation_imports
import 'dart:io';

// ignore: implementation_imports
import 'package:slang/src/builder/builder/slang_file_collection_builder.dart';

// ignore: implementation_imports
import 'package:slang/src/builder/builder/translation_map_builder.dart';

// ignore: implementation_imports
import 'package:slang/src/builder/model/i18n_locale.dart';

// ignore: implementation_imports
import 'package:slang/src/builder/model/translation_map.dart';

// ignore: implementation_imports
import 'package:slang/src/builder/utils/path_utils.dart';

// ignore: implementation_imports
import 'package:slang/src/builder/utils/regex_utils.dart';

// ignore: implementation_imports
import 'package:slang/src/runner/apply.dart';

// ignore: implementation_imports
import 'package:slang/src/runner/configure.dart';

// ignore: implementation_imports
import 'package:slang/src/runner/generate.dart';

Future<void> addLocale({
  required I18nLocale locale,
  required Map<String, dynamic> translations,
}) async {
  final fileCollection = SlangFileCollectionBuilder.readFromFileSystem(
    verbose: false,
  );

  // Create all necessary files for the new locale
  // based on the namespaces of the base locale
  for (final file in fileCollection.files) {
    if (file.locale != fileCollection.config.baseLocale) {
      continue;
    }

    if (fileCollection.config.namespaces) {
      final fileNameNoExtension = PathUtils.getFileNameNoExtension(file.path);
      final namespaceWithLocaleMatch =
          RegexUtils.fileWithLocaleRegex.firstMatch(fileNameNoExtension);

      if (namespaceWithLocaleMatch != null) {
        // Classical case: e.g. strings_en.i18n.json
        // Just replace the locale in the file name
        final path = PathUtils.replaceFileName(
          path: file.path,
          newFileName:
              '${file.namespace}_${locale.languageTag}${fileCollection.config.inputFilePattern}',
          pathSeparator: '/',
        );
        _createFile(path: path);
      } else {
        // Check if locale is in directory name
        final directoryLocale = PathUtils.findDirectoryLocale(
          filePath: file.path,
          inputDirectory: fileCollection.config.inputDirectory,
        );

        if (directoryLocale == null) {
          print('This should not happen: Cannot detect locale in ${file.path}');
          continue;
        }

        final segments = PathUtils.getPathSegments(file.path);
        segments[directoryLocale.localeSegmentIndex] = locale.languageTag;
        final namespacePrefix = directoryLocale.namespacePrefix.isEmpty
            ? ''
            : '${directoryLocale.namespacePrefix.join('/')}/';
        final path =
            '${segments.sublist(0, segments.length - 1).join('/')}/$namespacePrefix${file.namespace}${fileCollection.config.inputFilePattern}';
        _createFile(path: path);
      }
    } else {
      final path = PathUtils.replaceFileName(
        path: file.path,
        newFileName:
            '${locale.languageTag}${fileCollection.config.inputFilePattern}',
        pathSeparator: '/',
      );
      _createFile(path: path);
    }
  }

  final fileCollectionAfterCreate =
      SlangFileCollectionBuilder.readFromFileSystem(
    verbose: false,
  );

  final translationMap = await TranslationMapBuilder.build(
    fileCollection: fileCollectionAfterCreate,
  );

  await applyTranslationsForOneLocale(
    fileCollection: fileCollectionAfterCreate,
    applyLocale: locale,
    baseTranslations:
        translationMap[fileCollectionAfterCreate.config.baseLocale]!,
    newTranslations: ExpandedNamespaceMap(translations).flatten(
      namespaces: fileCollection.getNamespaces(),
    ),
  );

  final finalFileCollection = SlangFileCollectionBuilder.readFromFileSystem(
    verbose: false,
  );

  // Generate after applying with new translations
  await generateTranslations(
    fileCollection: finalFileCollection,
  );
  runConfigure(finalFileCollection);
}

void _createFile({
  required String path,
}) {
  final newFile = File(path);
  if (!newFile.existsSync()) {
    newFile.createSync(recursive: true);
    newFile.writeAsStringSync('');
  }
}
