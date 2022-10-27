import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/translation_map.dart';
import 'package:slang/builder/utils/map_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';

import 'slang.dart' as mainRunner;
import 'utils.dart' as utils;

const _file_prefix = 'missing_translations';
final _setEquality = SetEquality();

void main(List<String> arguments) async {
  mainRunner.main(['analyze', ...arguments]);
}

void generateMissingTranslations({
  required RawConfig rawConfig,
  required TranslationMap translationMap,
  required List<String> arguments,
}) {
  String? outDir;
  for (final a in arguments) {
    if (a.startsWith('--outdir=')) {
      outDir = a.substring(9).toAbsolutePath();
    }
  }
  if (outDir == null) {
    outDir = rawConfig.inputDirectory;
    if (outDir == null) {
      throw 'input_directory or --outdir=<path> must be specified.';
    }
  }

  final result = getMissingTranslations(
    rawConfig: rawConfig,
    translationMap: translationMap,
    flat: arguments.contains('--flat'),
  );

  if (arguments.contains('--split')) {
    // multiple files (split by locale)
    print('Output:');
    for (final entry in result.entries) {
      final path = PathUtils.withFileName(
        directoryPath: outDir,
        fileName: _file_prefix +
            '_' +
            entry.key.languageTag.replaceAll('-', '_') +
            '.${rawConfig.fileType.name}',
        pathSeparator: Platform.pathSeparator,
      );
      utils.writeFile(
        fileType: rawConfig.fileType,
        path: path,
        content: {
          ..._getInfoHeader(
            baseLocale: rawConfig.baseLocale,
            currLocale: entry.key,
            isEmpty: entry.value.isEmpty,
          ),
          ...entry.value,
        },
      );
      print(' -> $path');
    }
  } else {
    // join to one single file
    final path = PathUtils.withFileName(
      directoryPath: outDir,
      fileName: '$_file_prefix.${rawConfig.fileType.name}',
      pathSeparator: Platform.pathSeparator,
    );
    utils.writeFile(
      fileType: rawConfig.fileType,
      path: path,
      content: {
        ..._getInfoHeader(
          baseLocale: rawConfig.baseLocale,
          currLocale: null,
          isEmpty: result.values.every((v) => v.isEmpty),
        ),
        for (final entry in result.entries) entry.key.languageTag: entry.value,
      },
    );
    print('Output: $path');
  }
}

Map<I18nLocale, Map<String, dynamic>> getMissingTranslations({
  required RawConfig rawConfig,
  required TranslationMap translationMap,
  required bool flat,
}) {
  // build translation model
  final translationModelList = translationMap.toI18nModel(rawConfig);
  final baseTranslations =
      translationModelList.firstWhereOrNull((element) => element.base);
  if (baseTranslations == null) {
    throw 'There are no base translations. Could not found ${rawConfig.baseLocale.languageTag} in ${translationModelList.map((e) => e.locale.languageTag)}';
  }

  // use translation model and find missing translations
  Map<I18nLocale, Map<String, dynamic>> result = {};
  translationModelList.forEach((localeData) {
    if (localeData.base) {
      return;
    }

    final resultMap = <String, dynamic>{};
    _findMissingTranslations(
      baseNode: baseTranslations.root,
      curr: localeData.root,
      resultMap: resultMap,
      flat: flat,
    );
    result[localeData.locale] = resultMap;
  });

  return result;
}

/// Finds missing translations of one locale
/// and add them to [resultMap].
void _findMissingTranslations({
  required ObjectNode baseNode,
  required ObjectNode curr,
  required Map<String, dynamic> resultMap,
  required bool flat,
}) {
  for (final baseEntry in baseNode.entries.entries) {
    final baseChild = baseEntry.value;
    final currChild = curr.entries[baseEntry.key];
    if (!_checkEquality(baseChild, currChild)) {
      if (flat) {
        if (baseChild is TextNode) {
          resultMap[baseChild.rawPath] = baseChild.raw;
        } else {
          final childMap = <String, dynamic>{};
          _addNode(
            subIndex: baseChild.path.length + 1,
            node: baseChild,
            resultMap: childMap,
          );
          resultMap[baseChild.rawPath] = childMap;
        }
      } else {
        _addNode(
          subIndex: 0,
          node: baseChild,
          resultMap: resultMap,
        );
      }
    } else if (baseChild is ObjectNode && !baseChild.isMap) {
      _findMissingTranslations(
        baseNode: baseChild,
        curr: currChild as ObjectNode,
        resultMap: resultMap,
        flat: flat,
      );
    }
  }
}

/// Adds [node] to the [resultMap]
/// which includes all children of [node].
///
/// When [subIndex] is greater than zero,
/// then only a part of the path will be considered.
void _addNode({
  required int subIndex,
  required Node node,
  required Map<String, dynamic> resultMap,
}) {
  if (node is StringTextNode) {
    MapUtils.addItemToMap(
      map: resultMap,
      destinationPath: node.rawPath.substring(subIndex),
      item: node.raw,
    );
  } else if (node is RichTextNode) {
    MapUtils.addItemToMap(
      map: resultMap,
      destinationPath: node.rawPath.substring(subIndex),
      item: node.raw,
    );
  } else if (node is ListNode) {
    node.entries.forEach((child) {
      _addNode(subIndex: subIndex, node: child, resultMap: resultMap);
    });
  } else if (node is ObjectNode) {
    node.entries.values.forEach((child) {
      _addNode(subIndex: subIndex, node: child, resultMap: resultMap);
    });
  } else if (node is PluralNode) {
    node.quantities.values.forEach((child) {
      _addNode(subIndex: subIndex, node: child, resultMap: resultMap);
    });
  } else if (node is ContextNode) {
    node.entries.values.forEach((child) {
      _addNode(subIndex: subIndex, node: child, resultMap: resultMap);
    });
  } else {
    throw 'This should not happen';
  }
}

/// Both nodes are considered the same
/// when they have the same type and the same parameters.
bool _checkEquality(Node? a, Node? b) {
  if (a.runtimeType != b.runtimeType) {
    return false;
  }

  if (a is TextNode &&
      b is TextNode &&
      !_setEquality.equals(a.params, b.params)) {
    return false;
  }

  return true;
}

Map<String, List<String>> _getInfoHeader({
  required I18nLocale baseLocale,
  required I18nLocale? currLocale,
  required bool isEmpty,
}) {
  return {
    utils.INFO_KEY: [
      'Here are translations that exist in <${baseLocale.languageTag}> but not in ${currLocale != null ? '<${currLocale.languageTag}>' : 'secondary locales'}.',
      'After editing this file, you can run \'flutter pub run slang:apply\' to quickly apply the newly added translations.',
      if (isEmpty) 'Congratulations! There are no missing translations! :)',
    ]
  };
}
