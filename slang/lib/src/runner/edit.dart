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
import 'package:slang/src/builder/utils/regex_utils.dart';
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
  } else {
    locale = null;
    originPath = _getArgument(1, arguments);
    destinationPath = _getArgument(2, arguments);

    if (originPath == null) {
      throw 'Missing path.';
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
  final topLevelNamespaces = fileCollection.getTopLevelNamespaces();
  final destinationPathList = destinationPath.split('.');

  log.info('Operation: $originPath -> $destinationPath');
  log.info('');

  final origFiles = fileCollection.findFiles(
    path: originPath,
    topLevelNamespaces: topLevelNamespaces,
  );

  bool found = false;
  for (final origFile in origFiles) {
    final origMap = await origFile.file.readAndParse(config.fileType);

    final originValue = MapUtils.getValueAtPath(
      map: origMap,
      path: origFile.subPath,
    );

    if (originValue == null) {
      continue;
    }

    // Check if this is a rename (same parent path, just last key differs)
    final originSubPathList = origFile.subPath.split('.');
    final destSubPathForRename = config.namespaces
        ? resolveSubPath(
            path: destinationPath,
            namespace: origFile.file.namespace,
            topLevelNamespaces: topLevelNamespaces,
          )
        : destinationPath;

    final sameNamespace = destSubPathForRename != null;
    final destSubPathListForRename =
        (destSubPathForRename ?? destinationPath).split('.');
    final rename = sameNamespace &&
        originSubPathList.length == destSubPathListForRename.length &&
        const ListEquality().equals(
            originSubPathList
                .take(max(originSubPathList.length - 1, 0))
                .toList(),
            destSubPathListForRename
                .take(max(destSubPathListForRename.length - 1, 0))
                .toList());

    // Find the destination node
    if (rename) {
      log.info(
          '[${origFile.file.path}] Rename "$originPath" -> "$destinationPath"');
      MapUtils.updateEntry(
        map: origMap,
        path: origFile.subPath,
        update: (key, value) {
          return MapEntry(
            destinationPathList.last,
            value,
          );
        },
      );

      FileUtils.writeFileOfType(
        fileType: config.fileType,
        path: origFile.file.path,
        content: origMap,
      );

      found = true;
    } else {
      final destFile = fileCollection.findFile(
        path: destinationPath,
        locale: origFile.file.locale,
        topLevelNamespaces: topLevelNamespaces,
      );

      if (destFile == null) {
        continue;
      }

      log.info('[${origFile.file.path}] Delete "$originPath"');
      MapUtils.deleteEntry(
        map: origMap,
        path: origFile.subPath,
      );

      FileUtils.writeFileOfType(
        fileType: config.fileType,
        path: origFile.file.path,
        content: origMap,
      );

      final destMap = await destFile.file.readAndParse(config.fileType);

      log.info('[${destFile.file.path}] Add "$destinationPath"');
      MapUtils.addItemToMap(
        map: destMap,
        destinationPath: destFile.subPath,
        item: originValue!,
      );

      FileUtils.writeFileOfType(
        fileType: config.fileType,
        path: destFile.file.path,
        content: destMap,
      );

      found = true;
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
  final topLevelNamespaces = fileCollection.getTopLevelNamespaces();

  log.info('Operation: $originPath -> $destinationPath');
  log.info('');

  final origFiles = fileCollection.findFiles(
    path: originPath,
    topLevelNamespaces: topLevelNamespaces,
  );

  bool found = false;
  for (final origFile in origFiles) {
    final origMap = await origFile.file.readAndParse(config.fileType);

    final originValue = MapUtils.getValueAtPath(
      map: origMap,
      path: origFile.subPath,
    );

    if (originValue == null) {
      continue;
    }

    // Find the destination node
    final destFile = fileCollection.findFile(
      path: destinationPath,
      locale: origFile.file.locale,
      topLevelNamespaces: topLevelNamespaces,
    );

    if (destFile == null) {
      continue;
    }

    final destMap = await destFile.file.readAndParse(config.fileType);

    log.info('[${destFile.file.path}] Add "$destinationPath"');
    MapUtils.addItemToMap(
      map: destMap,
      destinationPath: destFile.subPath,
      item: originValue!,
    );

    FileUtils.writeFileOfType(
      fileType: config.fileType,
      path: destFile.file.path,
      content: destMap,
    );

    found = true;
  }

  if (!found) {
    log.info('No origin values found.');
  }
}

Future<void> _deleteEntry({
  required SlangFileCollection fileCollection,
  required String path,
}) async {
  final config = fileCollection.config;
  final resolvedFiles = fileCollection.findFiles(
    path: path,
  );

  for (final resolvedFile in resolvedFiles) {
    final file = resolvedFile.file;

    log.info('Deleting "$path" in ${file.path}...');

    final map = await file.readAndParse(config.fileType);

    MapUtils.deleteEntry(
      path: resolvedFile.subPath,
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
  final config = fileCollection.config;
  final resolvedFiles = fileCollection.findFiles(
    path: path,
  );

  if (resolvedFiles.isEmpty) {
    throw 'There is no namespace to fit "$path". Maybe create a ${RegexUtils.defaultNamespace}?';
  }

  for (final resolvedFile in resolvedFiles) {
    final file = resolvedFile.file;
    if (file.locale == config.baseLocale) {
      // We only want to add the key to non-base locales
      continue;
    }

    log.info('Adding flag to <${file.locale.languageTag}> in ${file.path}...');

    final Map<String, dynamic> parsedContent =
        await file.readAndParse(config.fileType);

    MapUtils.updateEntry(
      path: resolvedFile.subPath,
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
  final translationMap = await TranslationMapBuilder.build(
    fileCollection: fileCollection,
  );
  final config = fileCollection.config;
  final resolvedFiles = fileCollection.findFiles(
    path: path,
  );

  if (resolvedFiles.isEmpty) {
    throw 'There is no namespace to fit "$path". Maybe create a ${RegexUtils.defaultNamespace}?';
  }

  for (final resolvedFile in resolvedFiles) {
    final file = resolvedFile.file;
    if (locale != null && file.locale != locale) {
      continue;
    }

    final baseTranslationMap =
        translationMap[config.baseLocale]![file.namespace]!;

    log.info(
        'Adding translation to <${file.locale.languageTag}> in ${file.path}...');

    final Map<String, dynamic> oldMap =
        await file.readAndParse(config.fileType);

    final Map<String, dynamic> newMap = {};
    MapUtils.addItemToMap(
      map: newMap,
      destinationPath: resolvedFile.subPath,
      item: value,
    );

    final appliedTranslations = applyMapRecursive(
      baseMap: baseTranslationMap,
      newMap: newMap,
      oldMap: oldMap,
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
