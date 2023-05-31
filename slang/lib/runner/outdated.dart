import 'package:collection/collection.dart';
import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/model/slang_file_collection.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/map_utils.dart';
import 'package:slang/builder/utils/node_utils.dart';

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
    if (file.locale == config.baseLocale) {
      // We only want to add the key to non-base locales
      continue;
    }

    if (config.namespaces && file.namespace != targetNamespace) {
      // We only want to add the key to the target namespace
      continue;
    }

    await _updateEntry(
      path: config.namespaces ? pathList.skip(1).join('.') : path,
      locale: file.locale,
      file: file,
      fileType: config.fileType,
    );
  }
}

Future<void> _updateEntry({
  required String path,
  required I18nLocale locale,
  required TranslationFile file,
  required FileType fileType,
}) async {
  print('Adding flag to <${locale.languageTag}> in ${file.path}...');

  final Map<String, dynamic> parsedContent;
  try {
    parsedContent =
        BaseDecoder.getDecoderOfFileType(fileType).decode(await file.read());
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
