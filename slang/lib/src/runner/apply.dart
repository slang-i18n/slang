import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/src/builder/builder/translation_map_builder.dart';
import 'package:slang/src/builder/builder/translation_model_list_builder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/node.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/node_utils.dart';
import 'package:slang/src/builder/utils/path_utils.dart';
import 'package:slang/src/runner/analyze.dart';
import 'package:slang/src/runner/utils/read_analysis_file.dart';
import 'package:slang/src/utils/log.dart' as log;

const _supportedFiles = [FileType.json, FileType.yaml];

Future<void> runApplyTranslations({
  required SlangFileCollection fileCollection,
  required List<String> arguments,
}) async {
  final rawConfig = fileCollection.config;
  String? outDir;
  List<I18nLocale>? targetLocales; // only this locale will be considered
  for (final a in arguments) {
    if (a.startsWith('--outdir=')) {
      outDir = a.substring(9);
    } else if (a.startsWith('--locale=')) {
      targetLocales = [I18nLocale.fromString(a.substring(9))];
    }
  }

  if (outDir == null) {
    outDir = rawConfig.inputDirectory;
    if (outDir == null) {
      throw 'input_directory or --outdir=<path> must be specified.';
    }
  }

  final translationMap = await TranslationMapBuilder.build(
    fileCollection: fileCollection,
    verbose: false,
  );

  log.info('Looking for missing translations files in $outDir');
  final files =
      Directory(outDir).listSync(recursive: true).whereType<File>().toList();
  final missingTranslationsMap = readAnalysis(
    type: AnalysisType.missingTranslations,
    files: files,
    targetLocales: targetLocales,
  );

  if (targetLocales == null) {
    // If no locales are specified, then we only apply changed files
    // To know what has been changed, we need to regenerate the analysis
    log.info('');
    log.info('Regenerating analysis...');
    final analysis = getMissingTranslations(
      rawConfig: rawConfig,
      translations: TranslationModelListBuilder.build(
        rawConfig,
        translationMap,
      ),
    );

    final ignoreBecauseMissing = <I18nLocale>[];
    final ignoreBecauseEqual = <I18nLocale>[];
    for (final entry in {...missingTranslationsMap}.entries) {
      final locale = entry.key;
      final existingMissing = {...entry.value};
      final analysisMissing = analysis[entry.key];

      if (analysisMissing == null) {
        ignoreBecauseMissing.add(locale);
        missingTranslationsMap.remove(locale);
        continue;
      }

      if (DeepCollectionEquality().equals(existingMissing, analysisMissing)) {
        ignoreBecauseEqual.add(locale);
        missingTranslationsMap.remove(locale);
        continue;
      }
    }

    if (ignoreBecauseMissing.isNotEmpty) {
      log.info(
          ' -> Ignoring because missing in new analysis: ${ignoreBecauseMissing.joinedAsString}');
    }
    if (ignoreBecauseEqual.isNotEmpty) {
      log.info(
          ' -> Ignoring because no changes: ${ignoreBecauseEqual.joinedAsString}');
    }
  }

  if (missingTranslationsMap.isEmpty) {
    log.info('');
    log.info('No changes');
    return;
  }

  log.info('');
  log.info(
      'Applying: ${missingTranslationsMap.keys.map((l) => '<${l.languageTag}>').join(' ')}');

  // We need to read the base translations to determine
  // the order of the secondary translations
  final baseTranslationMap = translationMap[rawConfig.baseLocale]!;

  // The actual apply process:
  for (final entry in missingTranslationsMap.entries) {
    final locale = entry.key;
    final missingTranslations = entry.value;

    log.info(' -> Apply <${locale.languageTag}>');
    await _applyTranslationsForOneLocale(
      fileCollection: fileCollection,
      applyLocale: locale,
      baseTranslations: baseTranslationMap,
      newTranslations: missingTranslations,
    );
  }
}

/// Apply translations only for ONE locale.
/// Scans existing translations files, loads its content, and finally adds translations.
/// Throws an error if the file could not be found.
///
/// [newTranslations] is a map of "Namespace -> Translations"
Future<void> _applyTranslationsForOneLocale({
  required SlangFileCollection fileCollection,
  required I18nLocale applyLocale,
  required Map<String, Map<String, dynamic>> baseTranslations,
  required Map<String, dynamic> newTranslations,
}) async {
  final fileMap = <String, TranslationFile>{}; // namespace -> file

  for (final file in fileCollection.files) {
    if (file.locale == applyLocale) {
      fileMap[file.namespace] = file;
    }
  }

  if (fileMap.isEmpty) {
    throw 'Could not find a file for locale <${applyLocale.languageTag}>';
  }

  if (fileCollection.config.namespaces) {
    for (final entry in fileMap.entries) {
      if (!newTranslations.containsKey(entry.key)) {
        // This namespace exists but it is not specified in new translations
        continue;
      }
      await _applyTranslationsForFile(
        baseTranslations: baseTranslations[entry.key] ?? {},
        newTranslations: newTranslations[entry.key],
        destinationFile: entry.value,
      );
    }
  } else {
    // only apply for the first namespace
    await _applyTranslationsForFile(
      baseTranslations: baseTranslations.values.first,
      newTranslations: newTranslations,
      destinationFile: fileMap.values.first,
    );
  }
}

/// Reads the [destinationFile]. Applies [newTranslations] to it
/// while respecting the order of [baseTranslations].
///
/// In namespace mode, this function represents ONE namespace.
/// [baseTranslations] should also only contain the selected namespace.
///
/// If the key does not exist in [baseTranslations], then it will be appended
/// after known keys (i.e. at the end of the file).
Future<void> _applyTranslationsForFile({
  required Map<String, dynamic> baseTranslations,
  required Map<String, dynamic> newTranslations,
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
    newMap: newTranslations,
    oldMap: parsedContent,
    verbose: true,
  );

  FileUtils.writeFileOfType(
    fileType: fileType,
    path: existingFile.path,
    content: appliedTranslations,
  );
  _printApplyingDestination(existingFile);
}

/// Adds entries from [newMap] to [oldMap] while respecting the order specified
/// in [baseMap].
///
/// Modifiers of [baseMap] are applied.
///
/// Entries in [oldMap] get removed when they get replaced and have the "OUTDATED" modifier.
///
/// The returned map is a new instance (i.e. no side effects for the given maps)
Map<String, dynamic> applyMapRecursive({
  String? path,
  required Map<String, dynamic> baseMap,
  required Map<String, dynamic> newMap,
  required Map<String, dynamic> oldMap,
  required bool verbose,
}) {
  final resultMap = <String, dynamic>{};
  final resultKeys = <String>{}; // keys without modifiers

  // Keys that have been applied.
  // They do not have modifiers in their path.
  final Set<String> appliedKeys = {};

  // [newMap] but without modifiers
  newMap = {
    for (final entry in newMap.entries) entry.key.withoutModifiers: entry.value
  };

  // Add keys according to the order in base map.
  // Prefer new map over old map.
  for (final key in baseMap.keys) {
    final keyWithoutModifiers = key.withoutModifiers;
    final newEntry = newMap[keyWithoutModifiers];
    dynamic actualValue = newEntry ?? oldMap[key];
    if (actualValue == null) {
      continue;
    }
    final currPath = path == null ? key : '$path.$key';

    if (actualValue is Map) {
      actualValue = applyMapRecursive(
        path: currPath,
        baseMap: baseMap[key] is Map
            ? baseMap[key]
            : throw 'In the base translations, "$key" is not a map.',
        newMap: newEntry ?? {},
        oldMap: oldMap[key] ?? {},
        verbose: verbose,
      );
    }

    if (newEntry != null) {
      final split = key.split('(');
      appliedKeys.add(split.first);
      if (verbose) {
        _printAdding(currPath, actualValue);
      }
    }
    resultMap[key] = actualValue;
    resultKeys.add(keyWithoutModifiers);
  }

  // Add keys from old map that are unknown in base locale.
  // It may contain the OUTDATED modifier.
  for (final key in oldMap.keys) {
    final keyWithoutModifiers = key.withoutModifiers;
    if (resultKeys.contains(keyWithoutModifiers)) {
      continue;
    }

    // Check if the key is outdated and overwritten.
    final info = NodeUtils.parseModifiers(key);
    if (info.modifiers.containsKey(NodeModifiers.outdated) &&
        appliedKeys.contains(info.path)) {
      // This key is outdated and should not be added.
      continue;
    }

    final currPath = path == null ? key : '$path.$key';

    final newEntry = newMap[key];
    dynamic actualValue = newEntry ?? oldMap[key];
    if (actualValue is Map) {
      actualValue = applyMapRecursive(
        path: currPath,
        baseMap: {},
        newMap: newEntry ?? {},
        oldMap: oldMap[key],
        verbose: verbose,
      );
    }

    if (verbose && newEntry != null) {
      _printAdding(currPath, actualValue);
    }
    resultMap[key] = actualValue;
    resultKeys.add(keyWithoutModifiers);
  }

  // Add remaining new keys that are not in base locale and not in old map.
  for (final entry in newMap.entries) {
    final keyWithoutModifiers = entry.key.withoutModifiers;
    if (resultKeys.contains(keyWithoutModifiers)) {
      continue;
    }

    final currPath = path == null ? entry.key : '$path.${entry.key}';

    dynamic actualValue = entry.value;
    if (actualValue is Map) {
      actualValue = applyMapRecursive(
        path: currPath,
        baseMap: {},
        newMap: entry.value,
        oldMap: {},
        verbose: verbose,
      );
    }

    if (verbose) {
      _printAdding(currPath, actualValue);
    }
    resultMap[entry.key] = actualValue;
  }

  return resultMap;
}

class FileTypeNotSupportedError extends UnsupportedError {
  FileTypeNotSupportedError(String filePath)
      : super(
            'The file "$filePath" has an invalid file extension (supported: ${_supportedFiles.map((e) => e.name)})');
}

void _printApplyingDestination(TranslationFile file) {
  log.verbose('    -> Update ${file.path}');
}

void _printAdding(String path, Object value) {
  if (value is Map) {
    return;
  }
  log.verbose('    -> Set [$path]: "$value"');
}

extension on List<I18nLocale> {
  String get joinedAsString {
    return map((l) => '<${l.languageTag}>').join(' ');
  }
}
