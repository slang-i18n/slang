import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/decoder/csv_decoder.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/translation_file.dart';
import 'package:slang/builder/model/translation_map.dart';
import 'package:slang/builder/utils/path_utils.dart';
import 'package:slang/builder/utils/regex_utils.dart';

class TranslationMapBuilder {
  /// Read all files and build a [TranslationMap]
  /// containing all locales, their namespaces and their locales
  static Future<TranslationMap> build({
    required RawConfig rawConfig,
    required List<TranslationFile> files,
    required bool verbose,
  }) async {
    final translationMap = TranslationMap();
    final padLeft = verbose
        ? _getPadLeft(
            files: files,
            baseLocale: rawConfig.baseLocale.languageTag,
            namespaces: rawConfig.namespaces,
            inputDirectory: rawConfig.inputDirectory,
          )
        : 0;
    for (final file in files) {
      final content = await file.read();
      final Map<String, dynamic> translations;
      try {
        translations = BaseDecoder.getDecoderOfFileType(rawConfig.fileType)
            .decode(content);
      } on FormatException catch (e) {
        if (verbose) {
          print('');
        }
        throw 'File: ${file.path}\n$e';
      }

      final fileNameNoExtension = PathUtils.getFileNameNoExtension(file.path);
      final baseFileMatch =
          RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);
      if (baseFileMatch != null) {
        // base file (file without locale, may be multiples due to namespaces!)
        // could also be a non-base locale when directory name is a locale

        final namespace = baseFileMatch.group(1)!;

        if (rawConfig.fileType == FileType.csv &&
            CsvDecoder.isCompactCSV(content)) {
          // compact csv

          translations.forEach((key, value) {
            final locale = I18nLocale.fromString(key);
            final localeTranslations = value as Map<String, dynamic>;
            translationMap.addTranslations(
              locale: locale,
              namespace: namespace,
              translations: localeTranslations,
            );

            if (verbose) {
              final baseStr = locale == rawConfig.baseLocale ? '(base) ' : '';
              final namespaceStr = rawConfig.namespaces ? '($namespace) ' : '';
              print(
                  '${('$baseStr$namespaceStr${locale.languageTag}').padLeft(padLeft)} -> ${file.path}');
            }
          });
        } else {
          // json, yaml or normal csv

          // directory name could be a locale
          I18nLocale? directoryLocale = null;
          if (rawConfig.namespaces) {
            directoryLocale = PathUtils.findDirectoryLocale(
              filePath: file.path,
              inputDirectory: rawConfig.inputDirectory,
            );
          }

          final locale = directoryLocale ?? rawConfig.baseLocale;

          translationMap.addTranslations(
            locale: locale,
            namespace: namespace,
            translations: translations,
          );

          if (verbose) {
            final baseLog = locale == rawConfig.baseLocale ? '(base) ' : '';
            final namespaceLog = rawConfig.namespaces ? '($namespace) ' : '';
            print(
                '${'$baseLog$namespaceLog${locale.languageTag}'.padLeft(padLeft)} -> ${file.path}');
          }
        }
      } else {
        // secondary files (strings_x)
        final match =
            RegexUtils.fileWithLocaleRegex.firstMatch(fileNameNoExtension);
        if (match != null) {
          final namespace = match.group(1)!;
          final locale = I18nLocale(
            language: match.group(2)!,
            script: match.group(3),
            country: match.group(4),
          );

          translationMap.addTranslations(
            locale: locale,
            namespace: namespace,
            translations: translations,
          );

          if (verbose) {
            final baseStr = locale == rawConfig.baseLocale ? '(base) ' : '';
            final namespaceStr = rawConfig.namespaces ? '($namespace) ' : '';
            print(
                '${(baseStr + namespaceStr + locale.languageTag).padLeft(padLeft)} -> ${file.path}');
          }
        }
      }
    }

    if (translationMap
        .getLocales()
        .every((locale) => locale != rawConfig.baseLocale)) {
      if (verbose) {
        print('');
      }
      throw 'Translation file for base locale "${rawConfig.baseLocale.languageTag}" not found.';
    }

    return translationMap;
  }
}

const _BASE_STR_LENGTH = 7; // "(base) "

/// Determines the longest debug string used for PadLeft
int _getPadLeft(
    {required List<TranslationFile> files,
    required String baseLocale,
    required bool namespaces,
    required String? inputDirectory}) {
  int longest = 0;
  for (final file in files) {
    int currLength;
    final fileNameNoExtension = PathUtils.getFileNameNoExtension(file.path);
    final baseFileMatch =
        RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);

    if (baseFileMatch != null) {
      final namespace = baseFileMatch.group(1)!;
      I18nLocale? directoryLocale = null;
      if (namespaces) {
        directoryLocale = PathUtils.findDirectoryLocale(
          filePath: file.path,
          inputDirectory: inputDirectory,
        );
        currLength = namespace.length +
            (directoryLocale?.languageTag ?? baseLocale).length;
      } else {
        currLength = baseLocale.length;
      }
      if ((directoryLocale?.languageTag ?? baseLocale) == baseLocale) {
        currLength += _BASE_STR_LENGTH;
      }
    } else {
      final match =
          RegexUtils.fileWithLocaleRegex.firstMatch(fileNameNoExtension);
      if (match != null) {
        final namespace = match.group(1)!;
        final locale = I18nLocale(
          language: match.group(2)!,
          script: match.group(3),
          country: match.group(4),
        );

        if (namespaces) {
          currLength = namespace.length + locale.languageTag.length;
        } else {
          currLength = locale.languageTag.length;
        }
        if (locale.languageTag == baseLocale) {
          currLength += _BASE_STR_LENGTH;
        }
      } else {
        currLength = 0;
      }
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
