import 'package:slang/src/builder/decoder/base_decoder.dart';
import 'package:slang/src/builder/decoder/csv_decoder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:slang/src/utils/log.dart' as log;

class TranslationMapBuilder {
  /// This method transforms files to an intermediate model [TranslationMap].
  /// After this step,
  /// - we removed the environment (i.e. dart:io, build_runner)
  /// - we removed the file type (JSON, YAML, CSV) because everything is a map now
  ///
  /// The resulting map is in a unmodified state, so no actual i18n handling (plural, rich text) has been applied.
  static Future<TranslationMap> build({
    required SlangFileCollection fileCollection,
    required bool verbose,
  }) async {
    final rawConfig = fileCollection.config;
    final translationMap = TranslationMap();
    final padLeft = verbose
        ? _getPadLeft(
            files: fileCollection.files,
            baseLocale: rawConfig.baseLocale.languageTag,
            namespaces: rawConfig.namespaces,
            inputDirectory: rawConfig.inputDirectory,
          )
        : 0;
    for (final file in fileCollection.files) {
      final content = await file.read();
      final Map<String, dynamic> translations;
      try {
        translations =
            BaseDecoder.decodeWithFileType(rawConfig.fileType, content);
      } on FormatException catch (e) {
        if (verbose) {
          log.verbose('');
        }
        throw 'File: ${file.path}\n$e';
      }

      if (rawConfig.fileType == FileType.csv &&
          CsvDecoder.isCompactCSV(content)) {
        // compact csv

        for (final key in translations.keys) {
          final value = translations[key];

          final locale = I18nLocale.fromString(key);
          final localeTranslations = value as Map<String, dynamic>;
          translationMap.addTranslations(
            locale: locale,
            namespace: file.namespace,
            translations: localeTranslations,
          );

          if (verbose) {
            final baseStr = locale == rawConfig.baseLocale ? '(base) ' : '';
            final namespaceStr =
                rawConfig.namespaces ? '(${file.namespace}) ' : '';
            log.verbose(
                '${('$baseStr$namespaceStr${locale.languageTag}').padLeft(padLeft)} -> ${file.path}');
          }
        }
      } else {
        // json, yaml or normal csv

        translationMap.addTranslations(
          locale: file.locale,
          namespace: file.namespace,
          translations: translations,
        );

        if (verbose) {
          final baseLog = file.locale == rawConfig.baseLocale ? '(base) ' : '';
          final namespaceLog =
              rawConfig.namespaces ? '(${file.namespace}) ' : '';
          log.verbose(
              '${'$baseLog$namespaceLog${file.locale.languageTag}'.padLeft(padLeft)} -> ${file.path}');
        }
      }
    }

    if (translationMap
        .getLocales()
        .every((locale) => locale != rawConfig.baseLocale)) {
      if (verbose) {
        log.verbose('');
      }
      throw 'Translation file for base locale "${rawConfig.baseLocale.languageTag}" not found.';
    }

    return translationMap;
  }
}

const _BASE_STR_LENGTH = 7; // "(base) "

/// Determines the longest debug string used for PadLeft
int _getPadLeft({
  required List<TranslationFile> files,
  required String baseLocale,
  required bool namespaces,
  required String? inputDirectory,
}) {
  int longest = 0;
  for (final file in files) {
    int currLength = file.locale.languageTag.length;

    if (namespaces) {
      currLength += file.namespace.length;
    }

    if (file.locale.languageTag == baseLocale) {
      currLength += _BASE_STR_LENGTH;
    }

    if (currLength > longest) {
      longest = currLength;
    }
  }

  if (namespaces) {
    // (base) (namespace) locale
    return longest + 4; // add first space, '(', ')', and last space
  } else {
    // (base) locale
    return longest + 1; // only add first space
  }
}
