import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/builder/builder/translation_map_builder.dart';
import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/model/slang_file_collection.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/node_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';
import 'package:slang/builder/utils/regex_utils.dart';
import 'package:slang/runner/analyze.dart';

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

  print('Looking for missing translations files in $outDir');
  final files =
      Directory(outDir).listSync(recursive: true).whereType<File>().toList();
  final missingTranslationsMap = _readMissingTranslations(
    files: files,
    targetLocales: targetLocales,
  );

  if (targetLocales == null) {
    // If no locales are specified, then we only apply changed files
    // To know what has been changed, we need to regenerate the analysis
    print('');
    print('Regenerating analysis...');
    final analysis = getMissingTranslations(
      rawConfig: rawConfig,
      translations: translationMap.toI18nModel(rawConfig),
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
      print(
          ' -> Ignoring because missing in new analysis: ${ignoreBecauseMissing.joinedAsString}');
    }
    if (ignoreBecauseEqual.isNotEmpty) {
      print(
          ' -> Ignoring because no changes: ${ignoreBecauseEqual.joinedAsString}');
    }
  }

  if (missingTranslationsMap.isEmpty) {
    print('');
    print('No changes');
    return;
  }

  print('');
  print(
      'Applying: ${missingTranslationsMap.keys.map((l) => '<${l.languageTag}>').join(' ')}');

  // We need to read the base translations to determine
  // the order of the secondary translations
  final baseTranslationMap = translationMap[rawConfig.baseLocale]!;

  // The actual apply process:
  for (final entry in missingTranslationsMap.entries) {
    final locale = entry.key;
    final missingTranslations = entry.value;

    print(' -> Apply <${locale.languageTag}>');
    await _applyTranslationsForOneLocale(
      fileCollection: fileCollection,
      applyLocale: locale,
      baseTranslations: baseTranslationMap,
      newTranslations: missingTranslations,
    );
  }
}

/// Reads the missing translations.
/// If [targetLocales] is specified, then only these locales are read.
Map<I18nLocale, Map<String, dynamic>> _readMissingTranslations({
  required List<File> files,
  required List<I18nLocale>? targetLocales,
}) {
  final Map<I18nLocale, Map<String, dynamic>> resultMap = {};
  for (final file in files) {
    final fileName = PathUtils.getFileName(file.path);
    final fileNameMatch =
        RegexUtils.missingTranslationsFileRegex.firstMatch(fileName);
    if (fileNameMatch == null) {
      continue;
    }

    final locale = fileNameMatch.group(1) != null
        ? I18nLocale.fromString(fileNameMatch.group(1)!)
        : null;
    if (locale != null &&
        targetLocales != null &&
        !targetLocales.contains(locale)) {
      continue;
    }

    final fileType = _supportedFiles
        .firstWhereOrNull((type) => type.name == fileNameMatch.group(2)!);
    if (fileType == null) {
      throw FileTypeNotSupportedError(file.path);
    }
    final content = File(file.path).readAsStringSync();

    final Map<String, dynamic> parsedContent;
    try {
      parsedContent =
          BaseDecoder.getDecoderOfFileType(fileType).decode(content);
    } on FormatException catch (e) {
      print('');
      throw 'File: ${file.path}\n$e';
    }

    if (locale != null) {
      _printReading(locale, file);
      resultMap[locale] = {...parsedContent}..remove(INFO_KEY);
    } else {
      // handle file containing multiple locales
      for (final entry in parsedContent.entries) {
        if (entry.key.startsWith(INFO_KEY)) {
          continue;
        }

        final locale = I18nLocale.fromString(entry.key);

        if (targetLocales != null && !targetLocales.contains(locale)) {
          continue;
        }

        _printReading(locale, file);
        resultMap[locale] = entry.value;
      }
    }
  }

  return resultMap;
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
  final existingContent = await existingFile.read();
  final fileType = _supportedFiles.firstWhereOrNull(
      (type) => type.name == PathUtils.getFileExtension(existingFile.path));
  if (fileType == null) {
    throw FileTypeNotSupportedError(existingFile.path);
  }
  final Map<String, dynamic> parsedContent;
  try {
    parsedContent =
        BaseDecoder.getDecoderOfFileType(fileType).decode(existingContent);
  } on FormatException catch (e) {
    print('');
    throw 'File: ${existingFile.path}\n$e';
  }

  final appliedTranslations = applyMapRecursive(
    baseMap: baseTranslations,
    newMap: newTranslations,
    oldMap: parsedContent,
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
}) {
  final resultMap = <String, dynamic>{};
  final Set<String> overwrittenKeys = {}; // keys without modifiers

  // [newMap] but without modifiers
  newMap = {
    for (final entry in newMap.entries) entry.key.withoutModifiers: entry.value
  };

  // Add keys according to the order in base map.
  // Prefer new map over old map.
  for (final key in baseMap.keys) {
    final newEntry = newMap[key.withoutModifiers];
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
      );
    }

    if (newEntry != null) {
      final split = key.split('(');
      overwrittenKeys.add(split.first);
      _printAdding(currPath, actualValue);
    }
    resultMap[key] = actualValue;
  }

  // Add keys from old map that are unknown in base locale.
  // It may contain the OUTDATED modifier.
  for (final key in oldMap.keys) {
    if (resultMap.containsKey(key)) {
      continue;
    }

    // Check if the key is outdated and overwritten.
    final info = NodeUtils.parseModifiers(key);
    if (info.modifiers.containsKey(NodeModifiers.outdated) &&
        overwrittenKeys.contains(info.path)) {
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
      );
    }

    if (newEntry != null) {
      _printAdding(currPath, actualValue);
    }
    resultMap[key] = actualValue;
  }

  return resultMap;
}

class FileTypeNotSupportedError extends UnsupportedError {
  FileTypeNotSupportedError(String filePath)
      : super(
            'The file "$filePath" has an invalid file extension (supported: ${_supportedFiles.map((e) => e.name)})');
}

void _printReading(I18nLocale locale, File file) {
  print(' -> Reading <${locale.languageTag}> from ${file.path}');
}

void _printApplyingDestination(TranslationFile file) {
  print('    -> Update ${file.path}');
}

void _printAdding(String path, Object value) {
  if (value is Map) {
    return;
  }
  print('    -> Set [$path]: "$value"');
}

extension on List<I18nLocale> {
  String get joinedAsString {
    return map((l) => '<${l.languageTag}>').join(' ');
  }
}
