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
  final topLevelNamespaces =
      config.namespaces ? fileCollection.getTopLevelNamespaces() : <String>{};
  final destinationPathList = destinationPath.split('.');

  log.info('Operation: $originPath -> $destinationPath');
  log.info('');

  bool found = false;
  for (final origFile in fileCollection.files) {
    final String originSubPath;
    if (config.namespaces) {
      final resolved = _resolveSubPath(
        path: originPath,
        namespace: origFile.namespace,
        topLevelNamespaces: topLevelNamespaces,
      );
      if (resolved == null) continue;
      originSubPath = resolved;
    } else {
      originSubPath = originPath;
    }

    final origMap = await origFile.readAndParse(config.fileType);

    final originValue = MapUtils.getValueAtPath(
      map: origMap,
      path: originSubPath,
    );

    if (originValue == null) {
      continue;
    }

    // Check if this is a rename (same parent path, just last key differs)
    final originSubPathList = originSubPath.split('.');
    final destSubPathForRename = config.namespaces
        ? _resolveSubPath(
            path: destinationPath,
            namespace: origFile.namespace,
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
          '[${origFile.path}] Rename "$originPath" -> "$destinationPath"');
      MapUtils.updateEntry(
        map: origMap,
        path: originSubPath,
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
          continue;
        }

        final String resolvedDestSubPath;
        if (config.namespaces) {
          final resolved = _resolveSubPath(
            path: destinationPath,
            namespace: destFile.namespace,
            topLevelNamespaces: topLevelNamespaces,
          );
          if (resolved == null) continue;
          resolvedDestSubPath = resolved;
        } else {
          resolvedDestSubPath = destinationPath;
        }

        log.info('[${origFile.path}] Delete "$originPath"');
        MapUtils.deleteEntry(
          map: origMap,
          path: originSubPath,
        );

        FileUtils.writeFileOfType(
          fileType: config.fileType,
          path: origFile.path,
          content: origMap,
        );

        final destMap = await destFile.readAndParse(config.fileType);

        log.info('[${destFile.path}] Add "$destinationPath"');
        MapUtils.addItemToMap(
          map: destMap,
          destinationPath: resolvedDestSubPath,
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
  final topLevelNamespaces =
      config.namespaces ? fileCollection.getTopLevelNamespaces() : <String>{};

  log.info('Operation: $originPath -> $destinationPath');
  log.info('');

  bool found = false;
  for (final origFile in fileCollection.files) {
    final String originSubPath;
    if (config.namespaces) {
      final resolved = _resolveSubPath(
        path: originPath,
        namespace: origFile.namespace,
        topLevelNamespaces: topLevelNamespaces,
      );
      if (resolved == null) continue;
      originSubPath = resolved;
    } else {
      originSubPath = originPath;
    }

    final origMap = await origFile.readAndParse(config.fileType);

    final originValue = MapUtils.getValueAtPath(
      map: origMap,
      path: originSubPath,
    );

    if (originValue == null) {
      continue;
    }

    // Find the destination node
    for (final destFile in fileCollection.files) {
      if (destFile.locale != origFile.locale) {
        continue;
      }

      final String destSubPath;
      if (config.namespaces) {
        final resolved = _resolveSubPath(
          path: destinationPath,
          namespace: destFile.namespace,
          topLevelNamespaces: topLevelNamespaces,
        );
        if (resolved == null) continue;
        destSubPath = resolved;
      } else {
        destSubPath = destinationPath;
      }

      final destMap = await destFile.readAndParse(config.fileType);

      log.info('[${destFile.path}] Add "$destinationPath"');
      MapUtils.addItemToMap(
        map: destMap,
        destinationPath: destSubPath,
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
  final config = fileCollection.config;
  final topLevelNamespaces =
      config.namespaces ? fileCollection.getTopLevelNamespaces() : <String>{};

  for (final file in fileCollection.files) {
    final String subPath;
    if (config.namespaces) {
      final resolved = _resolveSubPath(
        path: path,
        namespace: file.namespace,
        topLevelNamespaces: topLevelNamespaces,
      );
      if (resolved == null) continue;
      subPath = resolved;
    } else {
      subPath = path;
    }

    log.info('Deleting "$path" in ${file.path}...');

    final map = await file.readAndParse(config.fileType);

    MapUtils.deleteEntry(
      path: subPath,
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
  final topLevelNamespaces =
      config.namespaces ? fileCollection.getTopLevelNamespaces() : <String>{};

  for (final file in fileCollection.files) {
    if (file.locale == config.baseLocale) {
      // We only want to add the key to non-base locales
      continue;
    }

    final String subPath;
    if (config.namespaces) {
      final resolved = _resolveSubPath(
        path: path,
        namespace: file.namespace,
        topLevelNamespaces: topLevelNamespaces,
      );
      if (resolved == null) continue;
      subPath = resolved;
    } else {
      subPath = path;
    }

    log.info('Adding flag to <${file.locale.languageTag}> in ${file.path}...');

    final Map<String, dynamic> parsedContent =
        await file.readAndParse(config.fileType);

    MapUtils.updateEntry(
      path: subPath,
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
  final topLevelNamespaces =
      config.namespaces ? fileCollection.getTopLevelNamespaces() : <String>{};

  for (final file in fileCollection.files) {
    if (locale != null && file.locale != locale) {
      continue;
    }

    final String subPath;
    if (config.namespaces) {
      final resolved = _resolveSubPath(
        path: path,
        namespace: file.namespace,
        topLevelNamespaces: topLevelNamespaces,
      );
      if (resolved == null) continue;
      subPath = resolved;
    } else {
      subPath = path;
    }

    final baseTranslationMap = config.namespaces
        ? translationMap[config.baseLocale]![file.namespace]!
        : translationMap[config.baseLocale]!.values.first;

    log.info(
        'Adding translation to <${file.locale.languageTag}> in ${file.path}...');

    final Map<String, dynamic> oldMap =
        await file.readAndParse(config.fileType);

    final Map<String, dynamic> newMap = {};
    MapUtils.addItemToMap(
      map: newMap,
      destinationPath: subPath,
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

/// Given a user-provided path and a file's namespace, returns the sub-path
/// within that namespace, or null if the path doesn't belong to it.
///
/// For _default namespace: matches if the path doesn't start with a known
/// top-level namespace.
/// For nested namespaces (e.g. "a.b"): matches if the path starts with "a.b.".
String? _resolveSubPath({
  required String path,
  required String namespace,
  required Set<String> topLevelNamespaces,
}) {
  final pathParts = path.split('.');

  if (namespace == RegexUtils.defaultNamespace) {
    if (topLevelNamespaces.contains(pathParts.first)) {
      return null;
    }
    return path;
  }

  final namespaceParts = namespace.split('.');
  if (pathParts.length <= namespaceParts.length) {
    return null;
  }

  for (int i = 0; i < namespaceParts.length; i++) {
    if (pathParts[i] != namespaceParts[i]) {
      return null;
    }
  }

  return pathParts.skip(namespaceParts.length).join('.');
}
