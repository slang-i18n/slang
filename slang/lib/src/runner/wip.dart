import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/src/builder/builder/slang_file_collection_builder.dart';
import 'package:slang/src/builder/builder/translation_map_builder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/builder/utils/path_utils.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';
import 'package:slang/src/builder/utils/string_interpolation_extensions.dart';
import 'package:slang/src/runner/analyze.dart';
import 'package:slang/src/runner/apply.dart';
import 'package:slang/src/utils/log.dart' as log;

const _supportedFiles = [FileType.json, FileType.yaml];

Future<bool> runWip({
  required SlangFileCollection fileCollection,
  required List<String> arguments,
}) async {
  final subCommand = arguments.firstOrNull;
  if (subCommand == null) {
    throw 'Missing sub command for "wip"';
  }
  switch (subCommand) {
    case 'apply':
      return await _runWipApply(
        fileCollection: fileCollection,
        arguments: arguments,
      );
    default:
      log.error('Usage: dart run slang wip apply');
      return false;
  }
}

sealed class _CasingNodeBase {
  Map<String, CasingNode> get children;
}

class CasingNodeRoot implements _CasingNodeBase {
  /// Maps lowercased key -> child node (original key is stored in [CasingNode.key]).
  @override
  final Map<String, CasingNode> children;

  const CasingNodeRoot({
    required this.children,
  });

  static Future<CasingNodeRoot> fromFileCollection(
    SlangFileCollection fileCollection, [
    TranslationMap? translationMap,
  ]) async {
    translationMap ??= await TranslationMapBuilder.build(
      fileCollection: fileCollection,
    );
    final baseTranslations = translationMap[fileCollection.config.baseLocale]!;

    if (fileCollection.config.namespaces) {
      return CasingNodeRoot.fromMap({
        for (final entry in baseTranslations.entries) entry.key: entry.value,
      });
    } else {
      return CasingNodeRoot.fromMap(baseTranslations.values.first);
    }
  }

  /// Recursively builds a [CasingNodeRoot] tree from a translation map.
  static CasingNodeRoot fromMap(Map<String, dynamic> map) {
    return CasingNodeRoot(children: _buildChildren(map));
  }

  static Map<String, CasingNode> _buildChildren(Map<String, dynamic> map) {
    final children = <String, CasingNode>{};
    for (final entry in map.entries) {
      final grandChildren = entry.value is Map<String, dynamic>
          ? _buildChildren(entry.value as Map<String, dynamic>)
          : <String, CasingNode>{};

      children[entry.key.toLowerCase()] = CasingNode(
        key: entry.key,
        children: grandChildren,
      );
    }
    return children;
  }
}

class CasingNode implements _CasingNodeBase {
  final String key;

  /// Key with a distinct casing -> occurrence count
  /// Used to decide for a correction based on majority occurrence
  /// if there are multiple keys with different casing.
  final Map<String, int>? newKeys;

  @override
  final Map<String, CasingNode> children;

  const CasingNode({
    required this.key,
    required this.children,
  }) : newKeys = null;

  CasingNode.withNewKeys({
    required this.key,
    required this.children,
    required this.newKeys,
  });
}

/// Returns true if a wip invocation has been found.
Future<bool> _runWipApply({
  required SlangFileCollection fileCollection,
  required List<String> arguments,
}) async {
  List<String>? sourceDirs;

  for (final a in arguments) {
    if (a.startsWith('--source-dirs=')) {
      sourceDirs = a.substring(14).split(',').map((s) => s.trim()).toList();
    }
  }

  sourceDirs ??= ['lib'];

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

  final translationMap = await TranslationMapBuilder.build(
    fileCollection: fileCollection,
  );
  final baseTranslations = translationMap[fileCollection.config.baseLocale]!;

  final baseLocale = fileCollection.config.baseLocale;
  final fileMap = <String, TranslationFile>{}; // namespace -> file

  for (final file in fileCollection.files) {
    if (file.locale == baseLocale) {
      fileMap[file.namespace] = file;
    }
  }

  final baseCasingTree =
      await CasingNodeRoot.fromFileCollection(fileCollection, translationMap);

  bool foundInvocations = false;
  for (final file in files) {
    final source = file.readAsStringSync();

    final invocations = WipInvocationCollection.findInString(
      translateVar: fileCollection.config.translateVar,
      source: source,
      interpolation: fileCollection.config.stringInterpolation,
      baseCasingTree: baseCasingTree,
    );

    if (invocations.list.isEmpty) {
      continue;
    }

    foundInvocations = true;

    if (fileCollection.config.namespaces) {
      for (final entry in fileMap.entries) {
        if (!invocations.map.containsKey(entry.key)) {
          // This namespace exists but it is not specified in new translations
          continue;
        }
        await _runWipApplyForFile(
          baseTranslations: baseTranslations[entry.key] ?? {},
          newTranslations: invocations.map[entry.key],
          destinationFile: entry.value,
        );
      }
    } else {
      // only apply for the first namespace
      await _runWipApplyForFile(
        baseTranslations: baseTranslations.values.first,
        newTranslations: invocations.map,
        destinationFile: fileMap.values.first,
      );
    }

    String updatedCode = source;
    log.info('${file.path}:');
    for (final invocation in invocations.list) {
      final parametersStr = invocation.parameterMap.isEmpty
          ? ''
          : '(${invocation.parameterMap.entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
      final replacement =
          '${fileCollection.config.translateVar}.${invocation.path}$parametersStr';
      final originalPath = invocations.correctedPaths[invocation.path];
      final correctionHint = originalPath != null
          ? 'CHANGED: ${originalPath.note.padLeft(4, ' ')}'
          : '   PATH OK   ';

      final correctionChange = originalPath != null
          ? ' // ${originalPath.original} -> ${invocation.path}'
          : '';
      log.info(
          ' -> [$correctionHint] ${invocation.original} -> $replacement$correctionChange');

      updatedCode = updatedCode.replaceAll(invocation.original, replacement);
    }

    file.writeAsStringSync(updatedCode);
  }

  if (!foundInvocations) {
    log.info(
        'No "${fileCollection.config.translateVar}.\$wip" usage found. (input: $sourceDirs)');
  }

  return foundInvocations;
}

Future<Map<String, dynamic>> readWipMapFromFileSystem({
  bool verbose = false,
}) async {
  final fileCollection = SlangFileCollectionBuilder.readFromFileSystem(
    verbose: verbose,
  );
  final baseCasingTree =
      await CasingNodeRoot.fromFileCollection(fileCollection);

  const sourceDirs = ['lib'];

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

  WipInvocationCollection? collection;
  for (final file in files) {
    final source = file.readAsStringSync();

    final invocations = WipInvocationCollection.findInString(
      translateVar: fileCollection.config.translateVar,
      source: source,
      interpolation: fileCollection.config.stringInterpolation,
      baseCasingTree: baseCasingTree,
    );

    if (invocations.list.isEmpty) {
      continue;
    }

    collection = collection?.merge(invocations) ?? invocations;
  }

  return collection?.map ?? {};
}

/// Walks the [path] segments through the [CasingNodeRoot] tree.
/// For segments that are NOT in the base locale key tree, records their
/// casing in [CasingNode.newKeys] so majority voting can be applied later.
///
/// Side effect:
/// - updates the [CasingNodeRoot] tree with new nodes for new segments
void _trackCasingOccurrences(String path, CasingNodeRoot root) {
  final parts = path.split('.');
  _CasingNodeBase current = root;

  for (final part in parts) {
    final lowerKey = part.toLowerCase();
    final child = current.children[lowerKey];

    if (child != null) {
      final newKeys = child.newKeys;
      if (newKeys == null) {
        // This segment exists in the base locale tree, just traverse deeper.
        current = child;
      } else {
        // Already tracking this new key, increment the count.
        newKeys[part] = (newKeys[part] ?? 0) + 1;
        current = child;
      }
    } else {
      // First time seeing this new key.
      final newNode = CasingNode.withNewKeys(
        key: part,
        children: <String, CasingNode>{},
        newKeys: {part: 1},
      );
      current.children[lowerKey] = newNode;
      current = newNode;
    }
  }
}

class _CorrectedPathResult {
  final String correctedPath;
  final double? confidence;

  _CorrectedPathResult({
    required this.correctedPath,
    required this.confidence,
  });
}

/// Corrects each segment of [path] (dot-separated) using the [CasingNode] tree,
/// replacing same letters but with different casing (typo).
/// For segments in the base locale tree, uses the base key.
/// For new segments (tracked via [CasingNode.newKeys]), uses majority voting.
/// Returns null if no corrections were needed to avoid unnecessary updates.
_CorrectedPathResult? _getCorrectPath(String path, CasingNodeRoot root) {
  final parts = path.split('.');
  final correctedParts = <String>[];
  _CasingNodeBase current = root;
  bool changed = false;

  final confidence = <double>[];

  for (final part in parts) {
    final child = current.children[part.toLowerCase()];
    if (child == null) {
      throw 'Path segment "$part" not found in base locale tree. Please report this to the developers.';
    }

    final String correctKey;
    var newKeys = child.newKeys;
    if (newKeys != null) {
      // This segment is new. Decide what casing we should use.
      if (newKeys.length == 1) {
        // Only one casing variant.
        correctKey = newKeys.keys.first;
      } else {
        // Majority voting: pick the casing with the highest occurrence count.
        correctKey =
            newKeys.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        confidence.add(newKeys[correctKey]! / newKeys.values.sum);
      }
    } else {
      // This segment exists in the base locale tree, use the original key.
      correctKey = child.key;
    }

    correctedParts.add(correctKey);
    current = child;
    if (correctKey != part) {
      changed = true;
    }
  }

  if (!changed) {
    return null;
  }

  return _CorrectedPathResult(
    correctedPath: correctedParts.join('.'),
    confidence: confidence.isEmpty ? null : confidence.sum / confidence.length,
  );
}

Future<void> _runWipApplyForFile({
  required Map<String, dynamic> baseTranslations,
  required Map<String, dynamic> newTranslations,
  required TranslationFile destinationFile,
}) async {
  final fileType = _supportedFiles.firstWhereOrNull(
      (type) => type.name == PathUtils.getFileExtension(destinationFile.path));
  if (fileType == null) {
    throw FileTypeNotSupportedError(destinationFile.path);
  }

  final parsedContent = await destinationFile.readAndParse(fileType);

  final appliedTranslations = applyMapRecursive(
    baseMap: baseTranslations,
    newMap: newTranslations,
    oldMap: parsedContent,
    verbose: true,
  );

  FileUtils.writeFileOfType(
    fileType: fileType,
    path: destinationFile.path,
    content: appliedTranslations,
  );
}

class CasingCorrection {
  final String original;

  /// The note that will be printed in the log.
  /// - "BASE" for corrections based on the base locale tree
  /// - "80%" for corrections based on majority voting
  final String note;

  CasingCorrection({
    required this.original,
    required this.note,
  });

  @override
  String toString() => '$original ($note)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CasingCorrection &&
          runtimeType == other.runtimeType &&
          original == other.original &&
          note == other.note;

  @override
  int get hashCode => original.hashCode ^ note.hashCode;
}

class WipInvocationCollection {
  final Map<String, dynamic> map;
  final List<WipInvocationMatch> list;

  /// Maps corrected path -> original path
  /// for casing corrections (e.g. "loginpage" -> "loginPage").
  final Map<String, CasingCorrection> correctedPaths;

  WipInvocationCollection({
    required this.map,
    required this.list,
    this.correctedPaths = const {},
  });

  // Caches the regex for a given translateVar
  static (String, RegExp)? _cachedRegex;

  static WipInvocationCollection findInString({
    required String translateVar,
    required String source,
    required StringInterpolation interpolation,
    required CasingNodeRoot baseCasingTree,
  }) {
    final sourceSanitized =
        source.sanitizeDartFileForAnalysis(removeSpaces: false);
    final RegExp regex;
    if (_cachedRegex?.$1 == translateVar) {
      regex = _cachedRegex!.$2;
    } else {
      regex = RegExp(
        translateVar + r'\.\$wip\.([a-zA-Z_.\d]+)\(\s*(.*)\s*,?\s*\)',
      );
      _cachedRegex = (translateVar, regex);
    }

    final invocationsList = <WipInvocationMatch>[];
    for (final match in regex.allMatches(sourceSanitized)) {
      String original = match.group(0)!;
      final path = match.group(1)!;
      String value = match.group(2)!;

      if (value.contains(')')) {
        // The regex is greedy and might capture too many closing parentheses.
        // We need to find the matching closing parenthesis for the opening one.
        final openParenIndex = original.indexOf('(');
        if (openParenIndex != -1) {
          int depth = 0;

          for (int i = openParenIndex; i < original.length; i++) {
            if (original[i] == '(') {
              depth++;
            } else if (original[i] == ')') {
              depth--;
              if (depth == 0) {
                // Found the matching closing paren!
                original = original.substring(0, i + 1);
                value = original.substring(openParenIndex + 1, i);
                break;
              }
            }
          }
        }
      }

      // Track occurrence count for each distinct casing of new path segments.
      _trackCasingOccurrences(path, baseCasingTree);

      final invocation = WipInvocationMatch.parse(
        interpolation: interpolation,
        original: original,
        path: path,
        value: value,
      );
      invocationsList.add(invocation);
    }

    final invocationsMap = <String, dynamic>{};
    final correctedPaths = <String, CasingCorrection>{};

    for (final invocation in invocationsList) {
      // Apply case-insensitive path correction against the base locale key
      // tree, using majority voting for new (non-base) segments.
      final correctedPath = _getCorrectPath(
        invocation.path,
        baseCasingTree,
      );

      if (correctedPath != null) {
        correctedPaths[correctedPath.correctedPath] = CasingCorrection(
          original: invocation.path,
          note: correctedPath.confidence == null
              ? 'BASE'
              : '${(correctedPath.confidence! * 100).round().toString()}%',
        );
        invocation.path = correctedPath.correctedPath;
      }

      MapUtils.addItemToMap(
        map: invocationsMap,
        destinationPath: invocation.path,
        item: invocation.sanitizedValue,
      );
    }

    return WipInvocationCollection(
      map: invocationsMap,
      list: invocationsList,
      correctedPaths: correctedPaths,
    );
  }

  WipInvocationCollection merge(WipInvocationCollection other) {
    return WipInvocationCollection(
      map: MapUtils.merge(
        base: map,
        other: other.map,
      ),
      list: [
        ...list,
        ...other.list,
      ],
      correctedPaths: {
        ...correctedPaths,
        ...other.correctedPaths,
      },
    );
  }
}

final _stringLiteralRegex =
    RegExp(r"""^\s*(['"])(.*)(\1),?\s*$""", dotAll: true);

class WipInvocationMatch {
  final String original;
  String path;

  final String sanitizedValue;

  /// Original call -> Sanitized parameter
  final Map<String, String> parameterMap;

  WipInvocationMatch({
    required this.original,
    required this.path,
    required this.sanitizedValue,
    required this.parameterMap,
  });

  static WipInvocationMatch parse({
    required StringInterpolation interpolation,
    required String original,
    required String path,
    required String value,
  }) {
    final string = _stringLiteralRegex.firstMatch(value);

    if (string != null) {
      final value = string.group(2)!;
      final parameterMap = <String, String>{};
      final String digestedInterpolation;
      switch (interpolation) {
        case StringInterpolation.dart:
          // Source is already in Dart-style
          digestedInterpolation = value.replaceDartInterpolation(
            replacer: (match) {
              final rawParam = match.startsWith(r'${')
                  ? match.substring(2, match.length - 1)
                  : match.substring(1, match.length);
              final sanitized =
                  rawParam.sanitizeParameterAndUniqueness(parameterMap);
              parameterMap[sanitized] = rawParam.trim();
              return '\${$sanitized}';
            },
          );
          break;
        case StringInterpolation.braces:
          digestedInterpolation = value.replaceDartInterpolation(
            replacer: (match) {
              final rawParam = match.startsWith(r'${')
                  ? match.substring(2, match.length - 1)
                  : match.substring(1, match.length);
              final sanitized =
                  rawParam.sanitizeParameterAndUniqueness(parameterMap);
              parameterMap[sanitized] = rawParam.trim();
              return '{$sanitized}';
            },
          );
        case StringInterpolation.doubleBraces:
          digestedInterpolation = value.replaceDartInterpolation(
            replacer: (match) {
              final rawParam = match.startsWith(r'${')
                  ? match.substring(2, match.length - 1)
                  : match.substring(1, match.length);
              final sanitized =
                  rawParam.sanitizeParameterAndUniqueness(parameterMap);
              parameterMap[sanitized] = rawParam.trim();
              return '{{$sanitized}}';
            },
          );
      }

      return WipInvocationMatch(
        original: original,
        path: path,
        sanitizedValue: digestedInterpolation,
        parameterMap: parameterMap,
      );
    } else {
      // This might be a variable or a function call
      // e.g. t.$wip.wow(testFunction())
      final rawParam = value;
      final sanitized = rawParam.sanitizeParameterAndUniqueness({});
      return WipInvocationMatch(
        original: original,
        path: path,
        sanitizedValue: switch (interpolation) {
          StringInterpolation.dart => '\$$sanitized',
          StringInterpolation.braces => '{$sanitized}',
          StringInterpolation.doubleBraces => '{{$sanitized}}',
        },
        parameterMap: {
          sanitized: rawParam.trim(),
        },
      );
    }
  }
}

final _underscoreRegex = RegExp(r'^_+');

extension on String {
  /// Sanitizes the parameter and ensures uniqueness within the existing parameters.
  String sanitizeParameterAndUniqueness(
    Map<String, String> existingParameters,
  ) {
    final original = trim();
    String curr = this;
    curr = sanitizeParameter();

    if (curr.contains('.')) {
      final lastPart = curr.split('.').last.sanitizeParameter();
      if (!existingParameters.hasConflictingBinding(
        original: original,
        sanitized: lastPart,
      )) {
        return lastPart;
      }

      final joinedParts = curr.toCase(CaseStyle.camel);
      if (!existingParameters.hasConflictingBinding(
        original: original,
        sanitized: joinedParts,
      )) {
        return joinedParts;
      }

      curr = joinedParts;
    }

    int counter = 2;
    String currWithoutCounter = curr;
    while (existingParameters.hasConflictingBinding(
      original: original,
      sanitized: curr,
    )) {
      curr = '$currWithoutCounter${counter++}';
    }

    return curr;
  }

  /// Removes any leading underscore characters and trims the result.
  /// Removes the method call.
  /// Removes trailing comma.
  String sanitizeParameter() {
    final s = replaceFirst(_underscoreRegex, '').trim();
    final parenIndex = s.indexOf('(');
    if (parenIndex != -1) {
      return s.substring(0, parenIndex);
    } else {
      final commaIndex = s.indexOf(',');
      if (commaIndex != -1) {
        return s.substring(0, commaIndex);
      }
      return s;
    }
  }
}

extension on Map<String, String> {
  bool hasConflictingBinding({
    required String original,
    required String sanitized,
  }) {
    final foundOriginal = this[sanitized];
    return foundOriginal != null && foundOriginal != original;
  }
}
