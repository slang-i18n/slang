import 'dart:io';

import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/runner/utils/read_analysis_file.dart';
import 'package:slang/src/utils/log.dart' as log;

/// Reads the "_unused_translations" file and removes the specified keys
/// from the translation files.
Future<void> runClean({
  required SlangFileCollection fileCollection,
  required List<String> arguments,
}) async {
  final config = fileCollection.config;
  String? outDir;
  for (final a in arguments) {
    if (a.startsWith('--outdir=')) {
      outDir = a.substring(9);
    }
  }

  if (outDir == null) {
    outDir = config.inputDirectory;
    if (outDir == null) {
      throw 'input_directory or --outdir=<path> must be specified.';
    }
  }

  final files =
      Directory(outDir).listSync(recursive: true).whereType<File>().toList();
  final unusedTranslationsMap = readAnalysis(
    type: AnalysisType.unusedTranslations,
    files: files,
    targetLocales: null,
  );

  for (final entry in unusedTranslationsMap.entries) {
    final locale = entry.key;
    final map = entry.value;

    if (map.isEmpty) {
      continue;
    }

    final entries = MapUtils.getFlatMap(map);

    log.info(' -> Cleaning <${locale.languageTag}>...');
    for (final entry in entries) {
      log.verbose('   - $entry');
    }

    await _deleteEntriesForLocale(
      fileCollection: fileCollection,
      locale: locale,
      paths: entries,
    );
  }

  log.info('Done.');
}

/// Deletes the specified entries from the translation files
/// of the given locale.
Future<void> _deleteEntriesForLocale({
  required SlangFileCollection fileCollection,
  required I18nLocale locale,
  required List<String> paths,
}) async {
  final config = fileCollection.config;
  // A map of translations to be written
  // namespace -> map
  final outputMap = <String, Map<String, dynamic>>{};

  // A map of files to be written
  // namespace -> file
  final fileMap = <String, TranslationFile>{};

  for (final path in paths) {
    final pathList = path.split('.');
    final targetNamespace = config.namespaces ? pathList.first : 'dummy';

    var intermediateMap = outputMap[targetNamespace];

    if (intermediateMap == null) {
      // load map
      final file = _findFileInCollection(
        fileCollection: fileCollection,
        locale: locale,
        namespace: targetNamespace,
      );

      if (file == null) {
        // no file found, skip
        continue;
      }

      final map = await file.readAndParse(config.fileType);
      outputMap[targetNamespace] = map;
      fileMap[targetNamespace] = file;
      intermediateMap = map;
    }

    // delete entry in cache
    MapUtils.deleteEntry(
      path: config.namespaces ? pathList.skip(1).join('.') : path,
      map: intermediateMap,
    );
  }

  // Final step: Write the result

  if (config.namespaces) {
    for (final entry in outputMap.entries) {
      final namespace = entry.key;
      final file = fileMap[namespace]!;
      final map = entry.value;
      MapUtils.clearEmptyMaps(map);

      FileUtils.writeFileOfType(
        fileType: config.fileType,
        path: file.path,
        content: map,
      );
    }
  } else {
    if (fileMap.isEmpty) {
      // All specified namespaces might not exist
      return;
    }

    final file = fileMap.values.first;
    final map = outputMap.values.first;
    MapUtils.clearEmptyMaps(map);

    FileUtils.writeFileOfType(
      fileType: config.fileType,
      path: file.path,
      content: map,
    );
  }
}

/// Returns the first file in the collection
/// that matches the given [locale] and [namespace].
TranslationFile? _findFileInCollection({
  required SlangFileCollection fileCollection,
  required I18nLocale locale,
  required String namespace,
}) {
  for (final file in fileCollection.files) {
    if (file.locale == locale &&
        (file.namespace == namespace || !fileCollection.config.namespaces)) {
      return file;
    }
  }
  return null;
}
