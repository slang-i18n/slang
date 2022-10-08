import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/decoder/csv_decoder.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/translation_file.dart';
import 'package:slang/builder/model/translation_map.dart';
import 'package:slang/builder/utils/path_utils.dart';
import 'package:slang/builder/utils/regex_utils.dart';

const _defaultPadLeft = 12;
const _namespacePadLeft = 24;

class TranslationMapBuilder {
  /// Read all files and build a [TranslationMap]
  /// containing all locales, their namespaces and their locales
  static Future<TranslationMap> build({
    required RawConfig rawConfig,
    required List<TranslationFile> files,
    required bool verbose,
  }) async {
    final translationMap = TranslationMap();
    final padLeft = rawConfig.namespaces ? _namespacePadLeft : _defaultPadLeft;
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
              final namespaceLog = rawConfig.namespaces ? '($namespace) ' : '';
              final base = locale == rawConfig.baseLocale ? '(base) ' : '';
              print(
                  '${('$base$namespaceLog${locale.languageTag}').padLeft(padLeft)} -> ${file.path}');
            }
          });
        } else {
          // json, yaml or normal csv

          // directory name could be a locale
          I18nLocale? directoryLocale = null;
          if (rawConfig.namespaces) {
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
            final namespaceLog = rawConfig.namespaces ? '($namespace) ' : '';
            print(
                '${(namespaceLog + locale.languageTag).padLeft(padLeft)} -> ${file.path}');
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
