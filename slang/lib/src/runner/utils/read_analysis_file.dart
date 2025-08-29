import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/src/builder/decoder/base_decoder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/path_utils.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/runner/apply.dart';
import 'package:slang/src/utils/log.dart' as log;

const _supportedFiles = [FileType.json, FileType.yaml];

enum AnalysisType {
  unusedTranslations('unused_translations'),
  missingTranslations('missing_translations');

  const AnalysisType(this.fileName);

  final String fileName;
}

/// Reads the analysis files.
/// If [targetLocales] is specified, then only these locales are read.
Map<I18nLocale, Map<String, dynamic>> readAnalysis({
  required AnalysisType type,
  required List<File> files,
  required List<I18nLocale>? targetLocales,
}) {
  final Map<I18nLocale, Map<String, dynamic>> resultMap = {};
  for (final file in files) {
    final fileName = PathUtils.getFileName(file.path);
    final fileNameMatch = RegexUtils.analysisFileRegex.firstMatch(fileName);
    if (fileNameMatch == null) {
      continue;
    }

    if (type.fileName != fileNameMatch.group(1)) {
      // not the correct file type
      continue;
    }

    final locale = fileNameMatch.group(2) != null
        ? I18nLocale.fromString(fileNameMatch.group(2)!)
        : null;
    if (locale != null &&
        targetLocales != null &&
        !targetLocales.contains(locale)) {
      continue;
    }

    final fileType = _supportedFiles
        .firstWhereOrNull((type) => type.name == fileNameMatch.group(3)!);
    if (fileType == null) {
      throw FileTypeNotSupportedError(file.path);
    }
    final content = File(file.path).readAsStringSync();

    final Map<String, dynamic> parsedContent;
    try {
      parsedContent = BaseDecoder.decodeWithFileType(fileType, content);
    } on FormatException catch (e) {
      log.verbose('');
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

        if (entry.value == null) {
          // in yaml, empty maps are parsed as null
          continue;
        }

        _printReading(locale, file);
        resultMap[locale] = entry.value;
      }
    }
  }

  return resultMap;
}

void _printReading(I18nLocale locale, File file) {
  log.verbose(' -> Reading <${locale.languageTag}> from ${file.path}');
}
