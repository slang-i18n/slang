import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/utils/map_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';
import 'package:slang/builder/utils/regex_utils.dart';

import 'slang.dart' as mainRunner;
import 'utils.dart' as utils;

const _supportedFiles = [FileType.json, FileType.yaml];

void main(List<String> arguments) async {
  mainRunner.main(['apply', ...arguments]);
}

Future<void> applyTranslations({
  required RawConfig rawConfig,
  required List<String> arguments,
}) async {
  String? outDir;
  for (final a in arguments) {
    if (a.startsWith('--outdir=')) {
      outDir = a.substring(9).toAbsolutePath();
    }
  }
  if (outDir == null) {
    outDir = rawConfig.inputDirectory;
    if (outDir == null) {
      throw 'input_directory or --outdir=<path> must be specified.';
    }
  }
  final isFlatMap = arguments.contains('--flat');

  final files =
      Directory(outDir).listSync(recursive: true).whereType<File>().toList();

  final missingTranslationFiles = files.where((file) {
    final fileName = PathUtils.getFileName(file.path);
    return RegexUtils.missingTranslationsFileRegex.hasMatch(fileName);
  }).toList();

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
      if (parsedContent.isEmpty) {
        continue;
      }

      _printApplying(locale, file);

      _applyTranslationsForOneLocale(
        rawConfig: rawConfig,
        applyLocale: locale,
        newTranslations: parsedContent,
        files: translationFiles,
        isFlatMap: isFlatMap,
      );
    } else {
      // handle file containing multiple locales
      for (final entry in parsedContent.entries) {
        if (entry.key.startsWith(utils.INFO_KEY)) {
          continue;
        }

        final translationMap = entry.value as Map;
        if (translationMap.isEmpty) {
          continue;
        }

        final locale = I18nLocale.fromString(entry.key);

        _printApplying(locale, file);

        _applyTranslationsForOneLocale(
          rawConfig: rawConfig,
          applyLocale: locale,
          newTranslations: entry.value,
          files: translationFiles,
          isFlatMap: isFlatMap,
        );
      }
    }
  }
}

/// Apply translations only for ONE locale.
/// Scans existing translations files, loads its content, and finally adds translations.
/// Throws an error if the file could not be found.
void _applyTranslationsForOneLocale({
  required RawConfig rawConfig,
  required I18nLocale applyLocale,
  required Map<String, dynamic> newTranslations,
  required List<File> files,
  required bool isFlatMap,
}) {
  final fileMap = <String, File>{}; // namespace -> file

  for (final file in files) {
    final fileNameNoExtension = PathUtils.getFileNameNoExtension(file.path);
    final baseFileMatch =
        RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);
    I18nLocale? directoryLocale = null;
    final directoryName = PathUtils.getParentDirectory(file.path);
    if (directoryName != null) {
      final match = RegexUtils.localeRegex.firstMatch(directoryName);
      if (match != null) {
        directoryLocale = I18nLocale(
          language: match.group(1)!,
          script: match.group(2),
          country: match.group(3),
        );
      }
    }

    if (baseFileMatch != null) {
      // a file without locale (but locale may be in directory name!)
      if (directoryLocale == applyLocale ||
          rawConfig.baseLocale == applyLocale) {
        fileMap[fileNameNoExtension] = file;
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
        isFlatMap: isFlatMap,
      );
    }
  } else {
    // only apply for the first namespace
    _applyTranslationsForFile(
      newTranslations: newTranslations,
      destinationFile: fileMap.entries.first.value,
      isFlatMap: isFlatMap,
    );
  }
}

void _applyTranslationsForFile({
  required Map<String, dynamic> newTranslations,
  required File destinationFile,
  required bool isFlatMap,
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
    isFlatMap: isFlatMap,
  );

  utils.writeFile(
    fileType: fileType,
    path: existingFile.path,
    content: parsedContent,
  );
  _printApplyingDestination(existingFile);
}

void _applyTranslationsForMap({
  required Map<String, dynamic> newTranslations,
  required Map<String, dynamic> existingTranslations,
  required bool isFlatMap,
}) {
  if (isFlatMap) {
    // newTranslations is a flat map
    for (final entry in newTranslations.entries) {
      if (entry.value is Map) {
        _applyTranslationsForMapRecursive(
          path: entry.key,
          newTranslations: newTranslations,
          existingTranslations: existingTranslations,
        );
        continue;
      }

      _printAdding(entry.key, entry.value);
      MapUtils.addItemToMap(
        map: existingTranslations,
        destinationPath: entry.key,
        item: entry.value,
      );
    }
  } else {
    _applyTranslationsForMapRecursive(
      path: '',
      newTranslations: newTranslations,
      existingTranslations: existingTranslations,
    );
  }
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
            'The file "${file.path}" has an invalid file extension (supported: json, yaml)');
}

void _printApplying(I18nLocale locale, File file) {
  print(' -> Reading <${locale.languageTag}> from ${file.path}');
}

void _printApplyingDestination(File file) {
  print('    -> Update ${file.path}');
}

void _printAdding(String path, String value) {
  print('    -> Set [$path] "$value"');
}
