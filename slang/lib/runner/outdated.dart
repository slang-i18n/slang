import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/map_utils.dart';
import 'package:slang/builder/utils/node_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';
import 'package:slang/builder/utils/regex_utils.dart';
import 'package:slang/runner/utils.dart';

const _supportedFiles = [FileType.json, FileType.yaml];

Future<void> runOutdated({
  required SlangFileCollection fileCollection,
  required List<String> arguments,
}) async {
  final config = fileCollection.config;

  if (!_supportedFiles.contains(config.fileType)) {
    throw '${config.fileType} is not supported. Supported: $_supportedFiles';
  }

  final path = arguments.firstOrNull;
  if (path == null) {
    throw 'Missing path. Expected: flutter pub run slang outdated my.path.to.key';
  }

  final pathList = path.split('.');
  if (config.namespaces && pathList.length <= 1) {
    throw 'Missing namespace + path. Expected: flutter pub run slang outdated myNamespace.my.path.to.key';
  }
  final targetNamespace = pathList.first;

  for (final file in fileCollection.files) {
    final fileNameNoExtension = PathUtils.getFileNameNoExtension(file.path);
    final baseFileMatch =
        RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);
    if (baseFileMatch != null) {
      // base file (file without locale, may be multiples due to namespaces!)
      // could also be a non-base locale when directory name is a locale
      final namespace = baseFileMatch.group(1)!;

      // directory name could be a locale
      I18nLocale? directoryLocale = null;
      if (config.namespaces) {
        directoryLocale = PathUtils.findDirectoryLocale(
          filePath: file.path,
          inputDirectory: config.inputDirectory,
        );
      }

      if (directoryLocale == null || directoryLocale == config.baseLocale) {
        // We only want to add the key to non-base locales
        continue;
      }

      if (config.namespaces && namespace != targetNamespace) {
        // We only want to add the key to the target namespace
        continue;
      }

      _updateEntry(
        path: config.namespaces ? pathList.skip(1).join('.') : path,
        locale: directoryLocale,
        file: file,
        fileType: config.fileType,
      );
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

        if (locale == config.baseLocale) {
          // We only want to add the key to non-base locales
          continue;
        }

        if (config.namespaces && namespace != targetNamespace) {
          // We only want to add the key to the target namespace
          continue;
        }

        _updateEntry(
          path: config.namespaces ? pathList.skip(1).join('.') : path,
          locale: locale,
          file: file,
          fileType: config.fileType,
        );
      }
    }
  }
}

void _updateEntry({
  required String path,
  required I18nLocale locale,
  required File file,
  required FileType fileType,
}) {
  print('Adding flag to <${locale.languageTag}> in ${file.path}...');

  final Map<String, dynamic> parsedContent;
  try {
    parsedContent = BaseDecoder.getDecoderOfFileType(fileType)
        .decode(file.readAsStringSync());
  } on FormatException catch (e) {
    print('');
    throw 'File: ${file.path}\n$e';
  }

  MapUtils.updateEntry(
    path: path,
    map: parsedContent,
    update: (key, value) {
      return MapEntry(
        key.withModifier(NodeModifiers.outdated),
        value,
      );
    },
  );

  FileUtils.writeFileOfType(
    fileType: fileType,
    path: file.path,
    content: parsedContent,
  );
}
