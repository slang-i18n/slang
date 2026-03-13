import 'dart:io';

import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/runner/edit.dart';
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
  final outputMap = FlatNamespaceMap({});

  // A map of files to be written
  // namespace -> file
  final fileMap = <String, TranslationFile>{
    for (final file in fileCollection.files)
      if (file.locale == locale) file.namespace: file
  };

  final topLevelNamespaces = fileCollection.getTopLevelNamespaces();

  for (final path in paths) {
    String? resolvedNamespace;
    String? subPath;

    for (final namespace in fileMap.keys) {
      final resolved = resolveSubPath(
        path: path,
        namespace: namespace,
        topLevelNamespaces: topLevelNamespaces,
      );
      if (resolved != null) {
        resolvedNamespace = namespace;
        subPath = resolved;
        break;
      }
    }

    if (resolvedNamespace == null || subPath == null) {
      continue;
    }

    var intermediateMap = outputMap[resolvedNamespace];

    if (intermediateMap == null) {
      // Not in RAM yet, read from file
      final file = fileMap[resolvedNamespace]!;
      final map = await file.readAndParse(config.fileType);
      outputMap[resolvedNamespace] = map;
      intermediateMap = map;
    }

    // Delete entry in RAM
    MapUtils.deleteEntry(
      path: subPath,
      map: intermediateMap,
    );
  }

  // Final step: Write the result
  for (final entry in outputMap.entries) {
    final file = fileMap[entry.key]!;
    final map = entry.value;
    MapUtils.clearEmptyMaps(map);

    FileUtils.writeFileOfType(
      fileType: config.fileType,
      path: file.path,
      content: map,
    );
  }
}
