import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_data.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/translation_map.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/map_utils.dart';
import 'package:slang/builder/utils/node_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';

final _setEquality = SetEquality();

void analyzeTranslations({
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
  final split = arguments.contains('--split');
  final full = arguments.contains('--full');

  // build translation model
  final translationModelList = translationMap.toI18nModel(rawConfig);
  final baseTranslations =
      translationModelList.firstWhereOrNull((element) => element.base);
  if (baseTranslations == null) {
    throw 'There are no base translations. Could not found ${rawConfig.baseLocale.languageTag} in ${translationModelList.map((e) => e.locale.languageTag)}';
  }

  final missingTranslationsResult = _getMissingTranslations(
    rawConfig: rawConfig,
    translationModelList: translationModelList,
    baseTranslations: baseTranslations,
  );

  _writeMap(
    outDir: outDir,
    fileNamePrefix: '_missing_translations',
    fileType: rawConfig.fileType,
    split: split,
    info: (locale, localeMap) {
      return [
        'Here are translations that exist in <${rawConfig.baseLocale.languageTag}> but not in ${locale != null ? '<${locale.languageTag}>' : 'secondary locales'}.',
        if (locale != null)
          'After editing this file, you can run \'flutter pub run slang apply --locale=${locale.languageTag}\' to quickly apply the newly added translations.'
        else if (localeMap.length > 1)
          // there are at least 2 secondary locales
          'After editing this file, you can run \'flutter pub run slang apply --locale=<locale>\' to quickly apply the newly added translations.'
        else
          'After editing this file, you can run \'flutter pub run slang apply\' to quickly apply the newly added translations.',
        if ((locale == null && localeMap.values.every((v) => v.isEmpty)) ||
            localeMap.isEmpty)
          'Congratulations! There are no missing translations! :)',
      ];
    },
    result: missingTranslationsResult,
  );

  final unusedTranslationsResult = _getUnusedTranslations(
    rawConfig: rawConfig,
    translationModelList: translationModelList,
    baseTranslations: baseTranslations,
    full: full,
  );

  _writeMap(
    outDir: outDir,
    fileNamePrefix: '_unused_translations',
    fileType: rawConfig.fileType,
    split: split,
    info: (locale, localeMap) {
      return [
        if (locale == null) ...[
          'Here are translations that exist in secondary locales but not in <${rawConfig.baseLocale.languageTag}>.',
          if (full)
            '[--full enabled] Furthermore, translations not used in \'lib/\' according to the \'${rawConfig.translateVar}.<path>\' pattern are written into <${rawConfig.baseLocale.languageTag}>.',
        ] else ...[
          if (locale == rawConfig.baseLocale)
            '[--full enabled] Here are translations not used in \'lib/\' according to the \'${rawConfig.translateVar}.<path>\' pattern'
          else
            'Here are translations that exist in <${locale.languageTag}> but not in <${rawConfig.baseLocale.languageTag}>.',
        ],
        if (!full)
          'You may run \'flutter pub run slang analyze --full\' to also check translations not used in the source code.',
        if ((locale == null && localeMap.values.every((v) => v.isEmpty)) ||
            localeMap.isEmpty)
          'Congratulations! There are no unused translations! :)',
      ];
    },
    result: unusedTranslationsResult,
  );
}

Map<I18nLocale, Map<String, dynamic>> _getMissingTranslations({
  required RawConfig rawConfig,
  required List<I18nData> translationModelList,
  required I18nData baseTranslations,
}) {
  // use translation model and find missing translations
  Map<I18nLocale, Map<String, dynamic>> result = {};
  translationModelList.forEach((localeData) {
    if (localeData.base) {
      return;
    }

    final resultMap = <String, dynamic>{};
    _getMissingTranslationsForOneLocaleRecursive(
      baseNode: baseTranslations.root,
      curr: localeData.root,
      resultMap: resultMap,
    );
    result[localeData.locale] = resultMap;
  });

  return result;
}

Map<I18nLocale, Map<String, dynamic>> _getUnusedTranslations({
  required RawConfig rawConfig,
  required List<I18nData> translationModelList,
  required I18nData baseTranslations,
  required bool full,
}) {
  // use translation model and find missing translations
  Map<I18nLocale, Map<String, dynamic>> result = {};
  translationModelList.forEach((localeData) {
    if (localeData.base) {
      if (full) {
        // scans the whole source code
        result[localeData.locale] = _getUnusedTranslationsInSourceCode(
          translateVar: rawConfig.translateVar,
          baseModel: localeData,
        );
      }
      return;
    }

    final resultMap = <String, dynamic>{};
    _getMissingTranslationsForOneLocaleRecursive(
      baseNode: localeData.root,
      curr: baseTranslations.root,
      resultMap: resultMap,
    );
    result[localeData.locale] = resultMap;
  });

  return result;
}

/// Finds translations that exist in [baseNode] but not in [curr].
/// Adds them to [resultMap].
void _getMissingTranslationsForOneLocaleRecursive({
  required ObjectNode baseNode,
  required ObjectNode curr,
  required Map<String, dynamic> resultMap,
}) {
  for (final baseEntry in baseNode.entries.entries) {
    final baseChild = baseEntry.value;
    final currChild = curr.entries[baseEntry.key];
    if (!_checkEquality(baseChild, currChild)) {
      // add whole base node which is expected
      _addNode(
        node: baseChild,
        resultMap: resultMap,
      );
    } else if (baseChild is ObjectNode && !baseChild.isMap) {
      _getMissingTranslationsForOneLocaleRecursive(
        baseNode: baseChild,
        curr: currChild as ObjectNode,
        resultMap: resultMap,
      );
    }
  }
}

void _addNode({
  required Node node,
  required Map<String, dynamic> resultMap,
}) {
  // add base node as is
  // intermediate map nodes are automatically created
  _addNodeRecursive(
    node: node,
    resultMap: resultMap,
  );
}

/// Adds [node] to the [resultMap]
/// which includes all children of [node].
void _addNodeRecursive({
  required Node node,
  required Map<String, dynamic> resultMap,
}) {
  if (node is StringTextNode) {
    MapUtils.addItemToMap(
      map: resultMap,
      destinationPath: node.rawPath,
      item: node.raw,
    );
  } else if (node is RichTextNode) {
    MapUtils.addItemToMap(
      map: resultMap,
      destinationPath: node.rawPath,
      item: node.raw,
    );
  } else if (node is ListNode) {
    node.entries.forEach((child) {
      _addNodeRecursive(node: child, resultMap: resultMap);
    });
  } else if (node is ObjectNode) {
    node.entries.values.forEach((child) {
      _addNodeRecursive(node: child, resultMap: resultMap);
    });
  } else if (node is PluralNode) {
    node.quantities.values.forEach((child) {
      _addNodeRecursive(node: child, resultMap: resultMap);
    });
  } else if (node is ContextNode) {
    node.entries.values.forEach((child) {
      _addNodeRecursive(node: child, resultMap: resultMap);
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

/// Scans the whole source code and returns all unused translations
Map<String, dynamic> _getUnusedTranslationsInSourceCode({
  required String translateVar,
  required I18nData baseModel,
}) {
  final flatMap = baseModel.root.toFlatMap();
  final sourceCode = _loadSourceCode();
  final resultMap = <String, dynamic>{};
  for (final entry in flatMap.entries) {
    final translationCall = '$translateVar.${entry.key}';
    if (!sourceCode.contains(translationCall)) {
      // add whole base node which is expected
      _addNode(
        node: entry.value,
        resultMap: resultMap,
      );
    }
  }
  return resultMap;
}

/// Loads all dart files in lib/
/// and joins them into a single (huge) string.
String _loadSourceCode() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  final buffer = StringBuffer();
  for (final file in files) {
    buffer.writeln(file.readAsStringSync());
  }

  return buffer.toString();
}

void _writeMap({
  required String outDir,
  required String fileNamePrefix,
  required FileType fileType,
  required bool split,
  required List<String> Function(I18nLocale?, Map localeResult) info,
  required Map<I18nLocale, Map<String, dynamic>> result,
}) {
  if (split) {
    // multiple files (split by locale)
    for (final entry in result.entries) {
      final path = PathUtils.withFileName(
        directoryPath: outDir,
        fileName: fileNamePrefix +
            '_' +
            entry.key.languageTag.replaceAll('-', '_') +
            '.${fileType.name}',
        pathSeparator: Platform.pathSeparator,
      );
      FileUtils.writeFileOfType(
        fileType: fileType,
        path: path,
        content: {
          INFO_KEY: info(entry.key, entry.value),
          ...entry.value,
        },
      );
      print(' -> $path');
    }
  } else {
    // join to one single file
    final path = PathUtils.withFileName(
      directoryPath: outDir,
      fileName: '$fileNamePrefix.${fileType.name}',
      pathSeparator: Platform.pathSeparator,
    );
    FileUtils.writeFileOfType(
      fileType: fileType,
      path: path,
      content: {
        INFO_KEY: info(null, result),
        for (final entry in result.entries) entry.key.languageTag: entry.value,
      },
    );
    print(' -> $path');
  }
}
