import 'dart:math';

import 'package:collection/collection.dart';
import 'package:slang/src/builder/builder/translation_map_builder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/node.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/builder/utils/node_utils.dart';
import 'package:slang/src/runner/apply.dart';
import 'package:slang/src/utils/log.dart' as log;

const _supportedFiles = [FileType.json, FileType.yaml];

enum EditOperation {
  add, // dart run slang edit add fr greetings.hello "Bonjour"
  move, // dart run slang edit move loginPage authPage
  copy, // dart run slang edit copy loginPage authPage
  delete, // dart run slang edit delete loginPage.title
  outdated, // dart run slang edit outdated loginPage.title
}

Future<void> runEdit({
  required SlangFileCollection fileCollection,
  required List<String> arguments,
}) async {
  final config = fileCollection.config;

  if (!_supportedFiles.contains(config.fileType)) {
    throw '${config.fileType} is not supported. Supported: $_supportedFiles';
  }

  if (arguments.isEmpty) {
    throw 'Missing operation. Expected: ${EditOperation.values.map((e) => e.name).join(', ')}';
  }

  final operation =
      EditOperation.values.firstWhereOrNull((e) => e.name == arguments.first);
  if (operation == null) {
    throw 'Invalid operation. Expected: ${EditOperation.values.map((e) => e.name).join(', ')}';
  }

  final I18nLocale? locale;
  final String? originPath;
  final String? destinationPath; // or value for "add"
  if (operation == EditOperation.add) {
    if (arguments.length == 4) {
      // add translation to specific locale: add en my.path "My value"
      locale = I18nLocale.fromString(arguments[1]);
      originPath = _getArgument(2, arguments);
      destinationPath = _getArgument(3, arguments);
    } else {
      // add translation to all locales: add my.path "My value"
      locale = null;
      originPath = _getArgument(1, arguments);
      destinationPath = _getArgument(2, arguments);
    }

    if (originPath == null) {
      throw 'Missing path.';
    }

    if (destinationPath == null) {
      throw 'Missing value.';
    }

    // Sanity check
    if (fileCollection.config.namespaces && originPath.split('.').length <= 1) {
      throw 'Missing namespace + path. Expected: dart run slang edit add myNamespace.my.path.to.key';
    }
  } else {
    locale = null;
    originPath = _getArgument(1, arguments);
    destinationPath = _getArgument(2, arguments);

    if (originPath == null) {
      throw 'Missing path.';
    }

    // Sanity check
    if (fileCollection.config.namespaces && originPath.split('.').length <= 1) {
      throw 'Missing namespace + path. Expected: dart run slang outdated myNamespace.my.path.to.key';
    }
  }

  switch (operation) {
    case EditOperation.move:
      log.info('Moving translations...\n');
      if (destinationPath == null) {
        throw 'Missing destination path.';
      }
      await _moveEntry(
        fileCollection: fileCollection,
        originPath: originPath,
        destinationPath: destinationPath,
      );
      break;
    case EditOperation.copy:
      log.info('Copying translations...\n');
      if (destinationPath == null) {
        throw 'Missing destination path.';
      }
      await _copyEntry(
        fileCollection: fileCollection,
        originPath: originPath,
        destinationPath: destinationPath,
      );
      break;
    case EditOperation.delete:
      log.info('Deleting translations...\n');
      await _deleteEntry(
        fileCollection: fileCollection,
        path: originPath,
      );
      break;
    case EditOperation.outdated:
      log.info('Adding outdated flags...\n');
      await _outdatedEntry(fileCollection: fileCollection, path: arguments[1]);
      break;
    case EditOperation.add:
      log.info('Adding translation...\n');
      if (arguments.length != 4 && arguments.length != 3) {
        throw 'Invalid arguments. Expected: dart run slang add myLocale myNamespace.my.path.to.key "My value" (or without locale)';
      }
      await _addEntry(
        fileCollection: fileCollection,
        locale: locale,
        path: originPath,
        value: destinationPath!,
      );
      break;
  }
}

Future<void> _moveEntry({
  required SlangFileCollection fileCollection,
  required String originPath,
  required String destinationPath,
}) async {
  final config = fileCollection.config;
  final originPathList = originPath.split('.');
  final originNamespace = originPathList.first;
  final destinationPathList = destinationPath.split('.');
  final destinationNamespace = destinationPathList.first;
  final rename = originPathList.length == destinationPathList.length &&
      (!config.namespaces || originNamespace == destinationNamespace) &&
      ListEquality().equals(
          originPathList.take(max(originPathList.length - 1, 0)).toList(),
          destinationPathList
              .take(max(destinationPathList.length - 1, 0))
              .toList());

  log.info('Operation: $originPath -> $destinationPath (rename: $rename)');
  log.info('');

  bool found = false;
  for (final origFile in fileCollection.files) {
    // Find the origin node
    if (config.namespaces && origFile.namespace != originNamespace) {
      // wrong namespace
      continue;
    }

    final origMap = await origFile.readAndParse(config.fileType);

    final originValue = MapUtils.getValueAtPath(
      map: origMap,
      path: config.namespaces ? originPathList.skip(1).join('.') : originPath,
    );

    if (originValue == null) {
      continue;
    }

    // Find the destination node
    if (rename) {
      log.verbose('[${origFile.path}] Rename "$originPath" -> "$destinationPath"');
      MapUtils.updateEntry(
        map: origMap,
        path: config.namespaces ? originPathList.skip(1).join('.') : originPath,
        update: (key, value) {
          return MapEntry(
            destinationPathList.last,
            value,
          );
        },
      );

      FileUtils.writeFileOfType(
        fileType: config.fileType,
        path: origFile.path,
        content: origMap,
      );

      found = true;
    } else {
      for (final destFile in fileCollection.files) {
        if (destFile.locale != origFile.locale) {
          // wrong locale
          continue;
        }

        if (config.namespaces && destFile.namespace != destinationNamespace) {
          // wrong namespace
          continue;
        }

        log.verbose('[${origFile.path}] Delete "$originPath"');
        MapUtils.deleteEntry(
          map: origMap,
          path:
              config.namespaces ? originPathList.skip(1).join('.') : originPath,
        );

        FileUtils.writeFileOfType(
          fileType: config.fileType,
          path: origFile.path,
          content: origMap,
        );

        final destMap = await destFile.readAndParse(config.fileType);

        log.verbose('[${destFile.path}] Add "$destinationPath"');
        MapUtils.addItemToMap(
          map: destMap,
          destinationPath: config.namespaces
              ? destinationPathList.skip(1).join('.')
              : destinationPath,
          item: originValue!,
        );

        FileUtils.writeFileOfType(
          fileType: config.fileType,
          path: destFile.path,
          content: destMap,
        );

        found = true;
      }
    }
  }

  if (!found) {
    log.info('No origin values found.');
  }
}

Future<void> _copyEntry({
  required SlangFileCollection fileCollection,
  required String originPath,
  required String destinationPath,
}) async {
  final config = fileCollection.config;
  final originPathList = originPath.split('.');
  final originNamespace = originPathList.first;
  final destinationPathList = destinationPath.split('.');
  final destinationNamespace = destinationPathList.first;

  log.info('Operation: $originPath -> $destinationPath');
  log.info('');

  bool found = false;
  for (final origFile in fileCollection.files) {
    // Find the origin node
    if (config.namespaces && origFile.namespace != originNamespace) {
      // wrong namespace
      continue;
    }

    final origMap = await origFile.readAndParse(config.fileType);

    final originValue = MapUtils.getValueAtPath(
      map: origMap,
      path: config.namespaces ? originPathList.skip(1).join('.') : originPath,
    );

    if (originValue == null) {
      continue;
    }

    // Find the destination node
    for (final destFile in fileCollection.files) {
      if (destFile.locale != origFile.locale) {
        // wrong locale
        continue;
      }

      if (config.namespaces && destFile.namespace != destinationNamespace) {
        // wrong namespace
        continue;
      }

      final destMap = await destFile.readAndParse(config.fileType);

      log.verbose('[${destFile.path}] Add "$destinationPath"');
      MapUtils.addItemToMap(
        map: destMap,
        destinationPath: config.namespaces
            ? destinationPathList.skip(1).join('.')
            : destinationPath,
        item: originValue!,
      );

      FileUtils.writeFileOfType(
        fileType: config.fileType,
        path: destFile.path,
        content: destMap,
      );

      found = true;
    }
  }

  if (!found) {
    log.info('No origin values found.');
  }
}

Future<void> _deleteEntry({
  required SlangFileCollection fileCollection,
  required String path,
}) async {
  final pathList = path.split('.');
  final targetNamespace = pathList.first;

  for (final file in fileCollection.files) {
    final config = fileCollection.config;

    if (config.namespaces && file.namespace != targetNamespace) {
      // We only want to delete the key from the target namespace
      continue;
    }

    log.info('Deleting "$path" in ${file.path}...');

    final map = await file.readAndParse(config.fileType);

    MapUtils.deleteEntry(
      path: config.namespaces ? pathList.skip(1).join('.') : path,
      map: map,
    );

    FileUtils.writeFileOfType(
      fileType: config.fileType,
      path: file.path,
      content: map,
    );
  }
}

Future<void> _outdatedEntry({
  required SlangFileCollection fileCollection,
  required String path,
}) async {
  final pathList = path.split('.');
  final targetNamespace = pathList.first;

  for (final file in fileCollection.files) {
    final config = fileCollection.config;

    if (file.locale == config.baseLocale) {
      // We only want to add the key to non-base locales
      continue;
    }

    if (config.namespaces && file.namespace != targetNamespace) {
      // We only want to add the key to the target namespace
      continue;
    }

    log.info('Adding flag to <${file.locale.languageTag}> in ${file.path}...');

    final Map<String, dynamic> parsedContent =
        await file.readAndParse(config.fileType);

    MapUtils.updateEntry(
      path: config.namespaces ? pathList.skip(1).join('.') : path,
      map: parsedContent,
      update: (key, value) {
        return MapEntry(
          key.withModifier(NodeModifiers.outdated),
          value,
        );
      },
    );

    FileUtils.writeFileOfType(
      fileType: config.fileType,
      path: file.path,
      content: parsedContent,
    );
  }
}

Future<void> _addEntry({
  required SlangFileCollection fileCollection,
  required I18nLocale? locale,
  required String path,
  required String value,
}) async {
  final pathList = path.split('.');
  final targetNamespace = pathList.first;

  final translationMap = await TranslationMapBuilder.build(
    fileCollection: fileCollection,
    verbose: false,
  );
  final config = fileCollection.config;
  final baseTranslationMap = config.namespaces
      ? translationMap[config.baseLocale]![targetNamespace]!
      : translationMap[config.baseLocale]!.values.first;

  for (final file in fileCollection.files) {
    if (locale != null && file.locale != locale) {
      // We only want to add the key to the target locale
      continue;
    }

    if (config.namespaces && file.namespace != targetNamespace) {
      // We only want to add the key to the target namespace
      continue;
    }

    log.info(
        'Adding translation to <${file.locale.languageTag}> in ${file.path}...');

    final Map<String, dynamic> oldMap =
        await file.readAndParse(config.fileType);

    final Map<String, dynamic> newMap = {};
    MapUtils.addItemToMap(
      map: newMap,
      destinationPath: config.namespaces ? pathList.skip(1).join('.') : path,
      item: value,
    );

    final appliedTranslations = applyMapRecursive(
      baseMap: baseTranslationMap,
      newMap: newMap,
      oldMap: oldMap,
      verbose: true,
    );

    FileUtils.writeFileOfType(
      fileType: config.fileType,
      path: file.path,
      content: appliedTranslations,
    );
  }
}

String? _getArgument(int position, List<String> arguments) {
  if (position < arguments.length) {
    return arguments[position];
  } else {
    return null;
  }
}
