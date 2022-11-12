import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/map_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';
import 'package:slang/builder/utils/regex_utils.dart';

const _supportedFiles = [FileType.json, FileType.yaml];

Future<void> runApplyTranslations({
  required RawConfig rawConfig,
  required List<String> arguments,
}) async {
  String? outDir;
  I18nLocale? targetLocale; // only this locale will be considered
  for (final a in arguments) {
    if (a.startsWith('--outdir=')) {
      outDir = a.substring(9).toAbsolutePath();
    } else if (a.startsWith('--locale=')) {
      targetLocale = I18nLocale.fromString(a.substring(9));
    }
  }
  if (outDir == null) {
    outDir = rawConfig.inputDirectory;
    if (outDir == null) {
      throw 'input_directory or --outdir=<path> must be specified.';
    }
  }

  if (targetLocale != null) {
    print('Target: <${targetLocale.languageTag}>');
  }
  print('Looking for missing translations files in $outDir');

  final files =
      Directory(outDir).listSync(recursive: true).whereType<File>().toList();

  final missingTranslationFiles = files.where((file) {
    final fileName = PathUtils.getFileName(file.path);
    return RegexUtils.missingTranslationsFileRegex.hasMatch(fileName);
  }).toList();

  if (missingTranslationFiles.isEmpty) {
    print('Could not find a missing translations file.');
    return;
  }

  final translationFiles = files
      .where((file) => file.path.endsWith(rawConfig.inputFilePattern))
      .toList();

  for (final file in missingTranslationFiles) {
    final fileName = PathUtils.getFileName(file.path);
    final fileNameMatch =
        RegexUtils.missingTranslationsFileRegex.firstMatch(fileName)!;
    final locale = fileNameMatch.group(1) != null
        ? I18nLocale.fromString(fileNameMatch.group(1)!)
        : null;
    final fileType = _supportedFiles
        .firstWhereOrNull((type) => type.name == fileNameMatch.group(2)!);
    if (fileType == null) {
      throw FileTypeNotSupportedError(file);
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
      // handle splitted file
      if (targetLocale != null && locale != targetLocale) {
        _printIgnore(locale, file);
        continue;
      }

      if (parsedContent.isEmpty) {
        _printEmpty(locale.languageTag, file);
        continue;
      }

      _printReading(locale, file);

      _applyTranslationsForOneLocale(
        rawConfig: rawConfig,
        applyLocale: locale,
        newTranslations: parsedContent..remove(INFO_KEY),
        candidateFiles: translationFiles,
      );
    } else {
      // handle file containing multiple locales
      for (final entry in parsedContent.entries) {
        if (entry.key.startsWith(INFO_KEY)) {
          continue;
        }

        final locale = I18nLocale.fromString(entry.key);

        if (targetLocale != null && locale != targetLocale) {
          _printIgnore(locale, file);
          continue;
        }

        final translationMap = entry.value as Map;
        if (translationMap.isEmpty) {
          _printEmpty(entry.key, file);
          continue;
        }

        _printReading(locale, file);

        _applyTranslationsForOneLocale(
          rawConfig: rawConfig,
          applyLocale: locale,
          newTranslations: entry.value,
          candidateFiles: translationFiles,
        );
      }
    }
  }
}

/// Apply translations only for ONE locale.
/// Scans existing translations files, loads its content, and finally adds translations.
/// Throws an error if the file could not be found.
///
/// [newTranslations] is a map of "Namespace -> Translations"
/// [candidateFiles] are files that are applied to; Only a subset may be used
void _applyTranslationsForOneLocale({
  required RawConfig rawConfig,
  required I18nLocale applyLocale,
  required Map<String, dynamic> newTranslations,
  required List<File> candidateFiles,
}) {
  final fileMap = <String, File>{}; // namespace -> file

  for (final file in candidateFiles) {
    final fileNameNoExtension = PathUtils.getFileNameNoExtension(file.path);
    final baseFileMatch =
        RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);

    if (baseFileMatch != null) {
      if (rawConfig.namespaces) {
        // a file without locale (but locale may be in directory name!)
        final directoryLocale = PathUtils.findDirectoryLocale(
          filePath: file.path,
          inputDirectory: rawConfig.inputDirectory,
        );
        if (directoryLocale == applyLocale ||
            rawConfig.baseLocale == applyLocale) {
          fileMap[fileNameNoExtension] = file;
        }
      }
    } else {
      // a file containing a locale
      final match =
          RegexUtils.fileWithLocaleRegex.firstMatch(fileNameNoExtension);

      if (match != null) {
        final namespace = match.group(1)!;
        final locale = I18nLocale(
          language: match.group(2)!,
          script: match.group(3),
          country: match.group(4),
        );

        if (locale == applyLocale) {
          fileMap[namespace] = file;
        }
      }
    }
  }

  if (fileMap.isEmpty) {
    throw 'Could not find a file for locale <${applyLocale.languageTag}>';
  }

  if (rawConfig.namespaces) {
    for (final entry in fileMap.entries) {
      if (!newTranslations.containsKey(entry.key)) {
        // This namespace exists but it is not specified in new translations
        continue;
      }
      _applyTranslationsForFile(
        newTranslations: newTranslations[entry.key],
        destinationFile: entry.value,
      );
    }
  } else {
    // only apply for the first namespace
    _applyTranslationsForFile(
      newTranslations: newTranslations,
      destinationFile: fileMap.entries.first.value,
    );
  }
}

void _applyTranslationsForFile({
  required Map<String, dynamic> newTranslations,
  required File destinationFile,
}) {
  final existingFile = destinationFile;
  final existingContent = existingFile.readAsStringSync();
  final fileType = _supportedFiles.firstWhereOrNull(
      (type) => type.name == PathUtils.getFileExtension(existingFile.path));
  if (fileType == null) {
    throw FileTypeNotSupportedError(existingFile);
  }
  final Map<String, dynamic> parsedContent;
  try {
    parsedContent =
        BaseDecoder.getDecoderOfFileType(fileType).decode(existingContent);
  } on FormatException catch (e) {
    print('');
    throw 'File: ${existingFile.path}\n$e';
  }

  _applyTranslationsForMap(
    newTranslations: newTranslations,
    existingTranslations: parsedContent,
  );

  FileUtils.writeFileOfType(
    fileType: fileType,
    path: existingFile.path,
    content: parsedContent,
  );
  _printApplyingDestination(existingFile);
}

void _applyTranslationsForMap({
  required Map<String, dynamic> newTranslations,
  required Map<String, dynamic> existingTranslations,
}) {
  _applyTranslationsForMapRecursive(
    path: '',
    newTranslations: newTranslations,
    existingTranslations: existingTranslations,
  );
}

void _applyTranslationsForMapRecursive({
  required String path,
  required Map<String, dynamic> newTranslations,
  required Map<String, dynamic> existingTranslations,
}) {
  for (final entry in newTranslations.entries) {
    final currPath = path.isNotEmpty ? '$path.${entry.key}' : entry.key;
    if (entry.value is Map) {
      _applyTranslationsForMapRecursive(
        path: currPath,
        newTranslations: entry.value,
        existingTranslations: existingTranslations,
      );
      continue;
    }

    _printAdding(currPath, entry.value);
    MapUtils.addItemToMap(
      map: existingTranslations,
      destinationPath: currPath,
      item: entry.value,
    );
  }
}

class FileTypeNotSupportedError extends UnsupportedError {
  FileTypeNotSupportedError(File file)
      : super(
            'The file "${file.path}" has an invalid file extension (supported: ${_supportedFiles.map((e) => e.name)})');
}

void _printEmpty(String locale, File file) {
  print(' -> Found empty <$locale> in ${file.path}');
}

void _printIgnore(I18nLocale locale, File file) {
  print(' -> Ignore <${locale.languageTag}> in ${file.path}');
}

void _printReading(I18nLocale locale, File file) {
  print(' -> Reading <${locale.languageTag}> from ${file.path}');
}

void _printApplyingDestination(File file) {
  print('    -> Update ${file.path}');
}

void _printAdding(String path, Object value) {
  print('    -> Set [$path] "$value"');
}
