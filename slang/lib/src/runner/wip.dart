import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/src/builder/builder/translation_map_builder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/builder/utils/path_utils.dart';
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

RegExp buildRegExp(String translateVar) {
  return RegExp(
    translateVar + r"""\.\$wip\.([a-zA-Z_.]+)\((?:'([^']*)'|"([^"]*)\")\)""",
  );
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

  final regex = buildRegExp(fileCollection.config.translateVar);

  bool foundInvocations = false;
  for (final file in files) {
    final sourceRaw = file.readAsStringSync();
    final source = sourceRaw.sanitizeDartFileForAnalysis(removeSpaces: false);

    final invocationsMap = <String, dynamic>{};
    final invocationsList = <_WipInvocationMatch>[];

    bool loggedFile = false;
    for (final match in regex.allMatches(source)) {
      if (!loggedFile) {
        loggedFile = true;
        log.info('${file.path}:');
      }
      foundInvocations = true;

      final path = match.group(1)!;
      final value = match.group(2) ?? match.group(3)!;

      final invocation = _WipInvocationMatch.parse(
        interpolation: fileCollection.config.stringInterpolation,
        original: match.group(0)!,
        path: path,
        value: value,
      );

      MapUtils.addItemToMap(
        map: invocationsMap,
        destinationPath: path,
        item: invocation.sanitizedValue,
      );
      invocationsList.add(invocation);
    }

    if (invocationsMap.isEmpty) {
      continue;
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

    if (fileCollection.config.namespaces) {
      for (final entry in fileMap.entries) {
        if (!invocationsMap.containsKey(entry.key)) {
          // This namespace exists but it is not specified in new translations
          continue;
        }
        await _runWipApplyForFile(
          baseTranslations: baseTranslations[entry.key] ?? {},
          newTranslations: invocationsMap[entry.key],
          destinationFile: entry.value,
        );
      }
    } else {
      // only apply for the first namespace
      await _runWipApplyForFile(
        baseTranslations: baseTranslations.values.first,
        newTranslations: invocationsMap,
        destinationFile: fileMap.values.first,
      );
    }

    String updatedCode = sourceRaw;
    for (final invocation in invocationsList) {
      final parametersStr = invocation.parameterMap.isEmpty
          ? ''
          : '(${invocation.parameterMap.entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
      final replacement =
          '${fileCollection.config.translateVar}.${invocation.path}$parametersStr';
      log.info(' -> ${invocation.original} -> $replacement');
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

Future<void> _runWipApplyForFile({
  required Map<String, dynamic> baseTranslations,
  required Map<String, dynamic> newTranslations,
  required TranslationFile destinationFile,
}) async {
  final existingFile = destinationFile;
  final fileType = _supportedFiles.firstWhereOrNull(
      (type) => type.name == PathUtils.getFileExtension(existingFile.path));
  if (fileType == null) {
    throw FileTypeNotSupportedError(existingFile.path);
  }

  final parsedContent = await existingFile.readAndParse(fileType);

  final appliedTranslations = applyMapRecursive(
    baseMap: baseTranslations,
    newMap: newTranslations,
    oldMap: parsedContent,
    verbose: true,
  );

  FileUtils.writeFileOfType(
    fileType: fileType,
    path: existingFile.path,
    content: appliedTranslations,
  );
}

class _WipInvocationMatch {
  final String original;
  final String path;

  /// The value of the first argument of the method call.
  /// Contains the Dart-style interpolation (using $)
  final String value;

  final String sanitizedValue;

  /// Original call -> Sanitized parameter
  final Map<String, String> parameterMap;

  _WipInvocationMatch({
    required this.original,
    required this.path,
    required this.value,
    required this.sanitizedValue,
    required this.parameterMap,
  });

  static _WipInvocationMatch parse({
    required StringInterpolation interpolation,
    required String original,
    required String path,
    required String value,
  }) {
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
            final sanitized = rawParam.sanitizedParameter();
            parameterMap[sanitized] = rawParam;
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
            final sanitized = rawParam.sanitizedParameter();
            parameterMap[sanitized] = rawParam;
            return '{$sanitized}';
          },
        );
      case StringInterpolation.doubleBraces:
        digestedInterpolation = value.replaceDartInterpolation(
          replacer: (match) {
            final rawParam = match.startsWith(r'${')
                ? match.substring(2, match.length - 1)
                : match.substring(1, match.length);
            final sanitized = rawParam.sanitizedParameter();
            parameterMap[sanitized] = rawParam;
            return '{{$sanitized}}';
          },
        );
    }

    return _WipInvocationMatch(
      original: original,
      path: path,
      value: value,
      sanitizedValue: digestedInterpolation,
      parameterMap: parameterMap,
    );
  }
}

final _underscoreRegex = RegExp(r'^_+');

extension on String {
  /// Removes any leading underscore character.
  String sanitizedParameter() {
    return replaceFirst(_underscoreRegex, '');
  }
}
