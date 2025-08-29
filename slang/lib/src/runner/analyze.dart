import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/src/builder/builder/translation_model_list_builder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_data.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/node.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/builder/utils/node_utils.dart';
import 'package:slang/src/builder/utils/path_utils.dart';
import 'package:slang/src/utils/log.dart' as log;

final _setEquality = SetEquality();

void runAnalyzeTranslations({
  required RawConfig rawConfig,
  required TranslationMap translationMap,
  required List<String> arguments,
}) {
  String? outDir;
  List<String>? sourceDirs;

  for (final a in arguments) {
    if (a.startsWith('--outdir=')) {
      outDir = a.substring(9);
    }
    if (a.startsWith('--source-dirs=')) {
      sourceDirs = a.substring(14).split(',').map((s) => s.trim()).toList();
    }
  }

  sourceDirs ??= ['lib'];

  if (outDir == null) {
    outDir = rawConfig.inputDirectory;
    if (outDir == null) {
      throw 'input_directory or --outdir=<path> must be specified.';
    }
  }
  final split = arguments.contains('--split');
  final splitMissing = split || arguments.contains('--split-missing');
  final splitUnused = split || arguments.contains('--split-unused');
  final full = arguments.contains('--full');
  final exitIfChanged = arguments.contains('--exit-if-changed');

  // build translation model
  final translationModelList = TranslationModelListBuilder.build(
    rawConfig,
    translationMap,
  );

  final missingTranslationsResult = getMissingTranslations(
    rawConfig: rawConfig,
    translations: translationModelList,
  );

  _writeMap(
    outDir: outDir,
    fileNamePrefix: '_missing_translations',
    fileType: rawConfig.fileType,
    exitIfChanged: exitIfChanged,
    split: splitMissing,
    info: (locale, localeMap) {
      return [
        'Here are translations that exist in <${rawConfig.baseLocale.languageTag}> but not in ${locale != null ? '<${locale.languageTag}>' : 'secondary locales'}.',
        if (locale != null)
          'After editing this file, you can run \'dart run slang apply --locale=${locale.languageTag}\' to quickly apply the newly added translations.'
        else if (localeMap.length > 1)
          // there are at least 2 secondary locales
          'After editing this file, you can run \'dart run slang apply --locale=<locale>\' to quickly apply the newly added translations.'
        else
          'After editing this file, you can run \'dart run slang apply\' to quickly apply the newly added translations.',
      ];
    },
    result: missingTranslationsResult,
  );

  final unusedTranslationsResult = getUnusedTranslations(
    rawConfig: rawConfig,
    translations: translationModelList,
    full: full,
    sourceDirs: sourceDirs,
  );

  _writeMap(
    outDir: outDir,
    fileNamePrefix: '_unused_translations',
    fileType: rawConfig.fileType,
    exitIfChanged: exitIfChanged,
    split: splitUnused,
    info: (locale, localeMap) {
      final sourceDirsList = sourceDirs!.map((dir) => '\'$dir/\'').join(', ');
      return [
        if (locale == null) ...[
          'Here are translations that exist in secondary locales but not in <${rawConfig.baseLocale.languageTag}>.',
          if (full)
            '[--full enabled] Furthermore, translations not used in $sourceDirsList according to the \'${rawConfig.translateVar}.<path>\' pattern are written into <${rawConfig.baseLocale.languageTag}>.',
        ] else ...[
          if (locale == rawConfig.baseLocale)
            '[--full enabled] Here are translations not used in $sourceDirsList according to the \'${rawConfig.translateVar}.<path>\' pattern'
          else
            'Here are translations that exist in <${locale.languageTag}> but not in <${rawConfig.baseLocale.languageTag}>.',
        ],
        if (!full)
          'You may run \'dart run slang analyze --full\' to also check translations not used in the source code.',
      ];
    },
    result: unusedTranslationsResult,
  );
}

Map<I18nLocale, Map<String, dynamic>> getMissingTranslations({
  required RawConfig rawConfig,
  required List<I18nData> translations,
}) {
  final baseTranslations = _findBaseTranslations(rawConfig, translations);

  // use translation model and find missing translations
  Map<I18nLocale, Map<String, dynamic>> result = {};
  for (final currTranslations in translations) {
    if (currTranslations.base) {
      continue;
    }

    final resultMap = <String, dynamic>{};
    _getMissingTranslationsForOneLocaleRecursive(
      baseNode: baseTranslations.root,
      curr: currTranslations.root,
      resultMap: resultMap,
      handleOutdated: true,
      ignoreModifierFlag: NodeModifiers.ignoreMissing,
      ignorePaths: const {},
    );
    result[currTranslations.locale] = resultMap;
  }

  return result;
}

Map<I18nLocale, Map<String, dynamic>> getUnusedTranslations({
  required RawConfig rawConfig,
  required List<I18nData> translations,
  required bool full,
  List<String>? sourceDirs,
}) {
  final baseTranslations = _findBaseTranslations(rawConfig, translations);

  // use translation model and find missing translations
  Map<I18nLocale, Map<String, dynamic>> result = {};
  for (final localeData in translations) {
    if (localeData.base) {
      if (full) {
        // scans the whole source code
        result[localeData.locale] = _getUnusedTranslationsInSourceCode(
          translateVar: rawConfig.translateVar,
          baseModel: localeData,
          sourceDirs: sourceDirs ?? ['lib'],
        );
      }
      continue;
    }

    final resultMap = <String, dynamic>{};
    final linkedPaths = <String>{};
    _getReferredPaths(localeData.root, linkedPaths);

    // { } = localeData - baseTranslations
    _getMissingTranslationsForOneLocaleRecursive(
      baseNode: localeData.root,
      curr: baseTranslations.root,
      resultMap: resultMap,
      handleOutdated: false,
      ignoreModifierFlag: NodeModifiers.ignoreUnused,
      ignorePaths: linkedPaths,
    );
    result[localeData.locale] = resultMap;
  }

  return result;
}

/// Finds translations that exist in [baseNode] but not in [curr].
/// Adds them to [resultMap].
void _getMissingTranslationsForOneLocaleRecursive({
  required ObjectNode baseNode,
  required ObjectNode curr,
  required Map<String, dynamic> resultMap,
  required bool handleOutdated,
  required String ignoreModifierFlag,
  required Set<String> ignorePaths,
}) {
  for (final baseEntry in baseNode.entries.entries) {
    final baseChild = baseEntry.value;
    if (baseChild.modifiers.containsKey(ignoreModifierFlag) ||
        ignorePaths.contains(baseChild.path)) {
      continue;
    }

    final currChild = curr.entries[baseEntry.key];
    final isOutdated = handleOutdated &&
        currChild?.modifiers.containsKey(NodeModifiers.outdated) == true;
    if (isOutdated ||
        currChild == null ||
        !_checkEquality(baseChild, currChild)) {
      if (baseChild is ContextNode && currChild is ContextNode) {
        // Only add missing enums
        for (final baseEnum in baseChild.entries.keys) {
          if (!currChild.entries.containsKey(baseEnum)) {
            _addNodeRecursive(
              node: baseChild.entries[baseEnum]!,
              resultMap: resultMap,
              addOutdatedModifier: isOutdated,
            );
          }
        }
      } else {
        // Add whole base node which is expected
        _addNodeRecursive(
          node: baseChild,
          resultMap: resultMap,
          addOutdatedModifier: isOutdated,
        );
      }
    } else if (baseChild is ObjectNode && !baseChild.isMap) {
      // [currChild] passed the previous equality check.
      // In this case, both [baseChild] and [currChild] are ObjectNodes
      // Let's check their children.
      _getMissingTranslationsForOneLocaleRecursive(
        baseNode: baseChild,
        curr: currChild as ObjectNode,
        resultMap: resultMap,
        handleOutdated: handleOutdated,
        ignoreModifierFlag: ignoreModifierFlag,
        ignorePaths: ignorePaths,
      );
    }
  }
}

/// Adds [node] to the [resultMap]
/// which includes all children of [node].
void _addNodeRecursive({
  required Node node,
  required Map<String, dynamic> resultMap,
  required bool addOutdatedModifier,
}) {
  if (node is StringTextNode) {
    MapUtils.addItemToMap(
      map: resultMap,
      destinationPath: addOutdatedModifier
          ? node.rawPath.withModifier(NodeModifiers.outdated)
          : node.rawPath,
      item: node.raw,
    );
  } else if (node is RichTextNode) {
    MapUtils.addItemToMap(
      map: resultMap,
      destinationPath: addOutdatedModifier
          ? node.rawPath.withModifier(NodeModifiers.outdated)
          : node.rawPath,
      item: node.raw,
    );
  } else {
    if (node is ListNode) {
      for (final child in node.entries) {
        _addNodeRecursive(
          node: child,
          resultMap: resultMap,
          addOutdatedModifier: false,
        );
      }
    } else if (node is ObjectNode) {
      for (final child in node.entries.values) {
        _addNodeRecursive(
          node: child,
          resultMap: resultMap,
          addOutdatedModifier: false,
        );
      }
    } else if (node is PluralNode) {
      for (final child in node.quantities.values) {
        _addNodeRecursive(
          node: child,
          resultMap: resultMap,
          addOutdatedModifier: false,
        );
      }
    } else if (node is ContextNode) {
      for (final child in node.entries.values) {
        _addNodeRecursive(
          node: child,
          resultMap: resultMap,
          addOutdatedModifier: false,
        );
      }
    } else {
      throw 'This should not happen';
    }

    if (addOutdatedModifier) {
      MapUtils.updateEntry(
        map: resultMap,
        path: node.path,
        update: (key, value) {
          return MapEntry(key.withModifier(NodeModifiers.outdated), value);
        },
      );
    }
  }
}

/// Both nodes are considered the same
/// when they have the same type and the same parameters.
bool _checkEquality(Node a, Node b) {
  if (a.runtimeType != b.runtimeType) {
    return false;
  }

  if (a is TextNode &&
      b is TextNode &&
      !_setEquality.equals(a.params, b.params)) {
    // different params
    return false;
  }

  if (a is ContextNode &&
      b is ContextNode &&
      !_setEquality.equals(a.entries.keys.toSet(), b.entries.keys.toSet())) {
    // different enums
    return false;
  }

  return true;
}

/// Scans the whole source code and returns all unused translations
Map<String, dynamic> _getUnusedTranslationsInSourceCode({
  required String translateVar,
  required I18nData baseModel,
  required List<String> sourceDirs,
}) {
  final resultMap = <String, dynamic>{};

  final files = <File>[];
  for (final sourceDir in sourceDirs) {
    final dir = Directory(sourceDir);
    if (dir.existsSync()) {
      files.addAll(
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList(),
      );
    }
  }

  _getUnusedTranslationsInSourceCodeRecursive(
    sourceCode: loadSourceCode(files),
    translateVar: translateVar,
    node: baseModel.root,
    resultMap: resultMap,
  );
  return resultMap;
}

void _getUnusedTranslationsInSourceCodeRecursive({
  required String sourceCode,
  required String translateVar,
  required ObjectNode node,
  required Map<String, dynamic> resultMap,
}) {
  for (final child in node.values) {
    if (child.modifiers.containsKey(NodeModifiers.ignoreUnused)) {
      continue;
    }

    if (child is ObjectNode && !child.isMap) {
      // recursive
      _getUnusedTranslationsInSourceCodeRecursive(
        sourceCode: sourceCode,
        translateVar: translateVar,
        node: child,
        resultMap: resultMap,
      );
    } else {
      final translationCall = '$translateVar.${child.path}';
      const linkedPrefix = r'${_root';

      // We only need to check if the translateVar is not part of the linked string.
      // Since most developers use the default "t" as translateVar,
      // we can ignore the linked call because it is already covered by the translateVar.
      final linkedCall = linkedPrefix.endsWith(translateVar)
          ? null
          : '$linkedPrefix.${child.path}';

      final isUsed = sourceCode.contains(translationCall) ||
          (linkedCall != null && sourceCode.contains(linkedCall));
      if (!isUsed) {
        // add whole base node which is expected
        _addNodeRecursive(
          node: child,
          resultMap: resultMap,
          addOutdatedModifier: false,
        );
      }
    }
  }
}

/// Loads all dart files in lib/
/// and joins them into a single (huge) string without any spaces.
String loadSourceCode(List<File> files) {
  final buffer = StringBuffer();
  final spacesRegex = RegExp(r'\s');
  final singleLineCommentsRegex = RegExp(r'//.*');
  final multiLineCommentsRegex = RegExp(r'/\*.*?\*/', dotAll: true);

  for (final file in files) {
    buffer.write(file
        .readAsStringSync()
        .replaceAll(singleLineCommentsRegex, '')
        .replaceAll(multiLineCommentsRegex, '')
        .replaceAll(spacesRegex, ''));
  }

  return buffer.toString();
}

I18nData _findBaseTranslations(RawConfig rawConfig, List<I18nData> i18nData) {
  final baseTranslations = i18nData.firstWhereOrNull((element) => element.base);
  if (baseTranslations == null) {
    throw 'There are no base translations. Could not found ${rawConfig.baseLocale.languageTag} in ${i18nData.map((e) => e.locale.languageTag)}';
  }
  return baseTranslations;
}

/// Populates [paths] with all paths that are referred in
/// linked translations.
void _getReferredPaths(ObjectNode root, Set<String> paths) {
  for (final entry in root.entries.entries) {
    final child = entry.value;
    switch (child) {
      case ObjectNode() when !child.isMap:
        _getReferredPaths(child, paths);
        break;
      case PluralNode():
        for (final quantity in child.quantities.values) {
          paths.addAll(quantity.links);
        }
        break;
      case ContextNode():
        for (final context in child.entries.values) {
          paths.addAll(context.links);
        }
        break;
      case TextNode():
        paths.addAll(child.links);
        break;
    }
  }
}

void _writeMap({
  required String outDir,
  required String fileNamePrefix,
  required FileType fileType,
  required bool exitIfChanged,
  required bool split,
  required List<String> Function(I18nLocale?, Map localeResult) info,
  required Map<I18nLocale, Map<String, dynamic>> result,
}) {
  if (split) {
    // multiple files (split by locale)
    for (final entry in result.entries) {
      final path = PathUtils.withFileName(
        directoryPath: outDir,
        fileName:
            '${fileNamePrefix}_${entry.key.languageTag.replaceAll('-', '_')}.${fileType.name}',
        pathSeparator: Platform.pathSeparator,
      );

      final fileContent = FileUtils.encodeContent(
        fileType: fileType,
        content: {
          INFO_KEY: info(entry.key, entry.value),
          ...entry.value,
        },
      );

      if (exitIfChanged) {
        final oldFile = File(path);
        if (oldFile.existsSync()) {
          if (fileContent != oldFile.readAsStringSync()) {
            // exit non-zero
            stderr.writeln('File changed: $path');
            exit(1);
          }
        }
      }

      FileUtils.writeFile(
        path: path,
        content: fileContent,
      );
      log.info(' -> $path');
    }
  } else {
    // join to one single file
    final path = PathUtils.withFileName(
      directoryPath: outDir,
      fileName: '$fileNamePrefix.${fileType.name}',
      pathSeparator: Platform.pathSeparator,
    );

    final fileContent = FileUtils.encodeContent(
      fileType: fileType,
      content: {
        INFO_KEY: info(null, result),
        for (final entry in result.entries) entry.key.languageTag: entry.value,
      },
    );

    if (exitIfChanged) {
      final oldFile = File(path);
      if (oldFile.existsSync()) {
        if (fileContent != oldFile.readAsStringSync()) {
          // exit non-zero
          stderr.writeln('File changed: $path');
          exit(1);
        }
      }
    }

    FileUtils.writeFile(
      path: path,
      content: fileContent,
    );
    log.info(' -> $path');
  }
}
