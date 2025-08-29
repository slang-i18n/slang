import 'package:collection/collection.dart';
import 'package:slang/src/builder/builder/translation_map_builder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/path_utils.dart';
import 'package:slang/src/runner/apply.dart';
import 'package:slang/src/utils/log.dart' as log;

const _supportedFiles = [FileType.json, FileType.yaml];

/// Normalizes the translation files according to the base locale.
Future<void> runNormalize({
  required SlangFileCollection fileCollection,
  required List<String> arguments,
}) async {
  I18nLocale? targetLocale; // only this locale will be considered
  for (final a in arguments) {
    if (a.startsWith('--locale=')) {
      targetLocale = I18nLocale.fromString(a.substring(9));
    }
  }

  final translationMap = await TranslationMapBuilder.build(
    fileCollection: fileCollection,
    verbose: false,
  );

  final baseTranslationMap = translationMap[fileCollection.config.baseLocale]!;

  if (targetLocale != null) {
    log.info('Target: <${targetLocale.languageTag}>');

    await _normalizeLocale(
      fileCollection: fileCollection,
      locale: targetLocale,
      baseTranslations: baseTranslationMap,
    );
  } else {
    log.info('Target: all locales');

    for (final locale in translationMap.getLocales()) {
      if (locale == fileCollection.config.baseLocale) {
        continue;
      }

      await _normalizeLocale(
        fileCollection: fileCollection,
        locale: locale,
        baseTranslations: baseTranslationMap,
      );
    }
  }

  log.info('Normalization finished!');
}

/// Normalizes all files for the given [locale].
Future<void> _normalizeLocale({
  required SlangFileCollection fileCollection,
  required I18nLocale locale,
  required Map<String, Map<String, dynamic>> baseTranslations,
}) async {
  final fileMap = <String, TranslationFile>{}; // namespace -> file

  for (final file in fileCollection.files) {
    if (file.locale == locale) {
      fileMap[file.namespace] = file;
    }
  }

  if (fileMap.isEmpty) {
    throw 'Could not find a file for locale <${locale.languageTag}>';
  }

  for (final entry in fileMap.entries) {
    await _normalizeFile(
      baseTranslations: baseTranslations[entry.key] ?? {},
      destinationFile: entry.value,
    );
  }
}

/// Reads the [destinationFile]
/// and normalizes the order according to [baseTranslations].
///
/// In namespace mode, this function represents ONE namespace.
/// [baseTranslations] should also only contain the selected namespace.
Future<void> _normalizeFile({
  required Map<String, dynamic> baseTranslations,
  required TranslationFile destinationFile,
}) async {
  final existingFile = destinationFile;
  final fileType = _supportedFiles.firstWhereOrNull(
      (type) => type.name == PathUtils.getFileExtension(existingFile.path));
  if (fileType == null) {
    throw FileTypeNotSupportedError(existingFile.path);
  }

  final parsedContent = await existingFile.readAndParse(fileType);

  final appliedTranslations = applyMapRecursive(
    baseMap: baseTranslations,
    newMap: const {},
    oldMap: parsedContent,
    verbose: true,
  );

  FileUtils.writeFileOfType(
    fileType: fileType,
    path: existingFile.path,
    content: appliedTranslations,
  );
}
