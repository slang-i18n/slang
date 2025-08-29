import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/utils/brackets_utils.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';
import 'package:slang/src/builder/utils/string_interpolation_extensions.dart';
import 'package:slang/src/utils/log.dart' as log;

final _setEquality = SetEquality();

Future<void> migrateArbRunner({
  required String sourcePath,
  required String destinationPath,
}) async {
  log.info('Migrating ARB to JSON...');

  final source = await File(sourcePath).readAsString();
  final resultMap = migrateArb(source);

  FileUtils.createMissingFolders(filePath: destinationPath);
  FileUtils.writeFile(
    path: destinationPath,
    content: JsonEncoder.withIndent('  ').convert(resultMap),
  );

  log.info('');
  log.info(
      'Please don\'t forget to configure the correct string_interpolation in build.yaml');
  log.info('');
  log.info('File generated: $destinationPath');
}

Map<String, dynamic> migrateArb(String raw, [bool verbose = true]) {
  final sourceMap = json.decode(raw);
  final resultMap = <String, dynamic>{};

  if (sourceMap is! Map<String, dynamic>) {
    throw 'ARB files must be a JSON object';
  }

  List<Set<String>> detectedContexts = [];
  List<String> detectedContextNames = []; // index matches with detectedContexts

  sourceMap.forEach((key, value) {
    if (key.startsWith('@@')) {
      // add without modifications
      MapUtils.addItemToMap(
        map: resultMap,
        destinationPath: key,
        item: value.toString(),
      );
      return;
    }
    final bool isMeta = key.startsWith('@');
    if (isMeta) {
      key = key.substring(1);
    }

    final keyParts = <String>[];
    key.getWords().forEach((part) {
      final subPathInt = int.tryParse(part);
      if (subPathInt == null) {
        // add normal key part
        keyParts.add(part.toLowerCase());
      } else {
        // this key part is a number
        if (keyParts.isEmpty) {
          throw 'Keys cannot start with a number: $key';
        }

        // add number to last part as suffix
        keyParts[keyParts.length - 1] = '${keyParts.last}$subPathInt';
      }
    });

    if (isMeta) {
      _digestMeta(
        keyParts,
        value is Map<String, dynamic> ? value : {},
        resultMap,
      );
    } else {
      final contextResult = _digestEntry(keyParts, value, resultMap);
      for (final c in contextResult) {
        if (detectedContexts
            .every((c2) => !_setEquality.equals(c2, c.contextEnum))) {
          // detected new context
          detectedContexts.add(c.contextEnum);
          detectedContextNames.add(c.contextName);
        }
      }
    }
  });

  if (verbose && detectedContexts.isNotEmpty) {
    log.info('');
    log.info('Detected contexts (please define them in build.yaml):');
    const suffixes = ['Context', 'Type'];
    for (int i = 0; i < detectedContexts.length; i++) {
      final contextName = detectedContextNames[i].toCase(CaseStyle.pascal);
      final contextNameLower = contextName.toLowerCase();
      final hasSuffix = suffixes
          .any((suffix) => contextNameLower.contains(suffix.toLowerCase()));
      final additionalNames = hasSuffix
          ? []
          : suffixes
              .where((suffix) => !contextNameLower.contains(suffix))
              .map((suffix) => _contextNameWithSuffix(contextName, suffix))
              .toList();

      log.info('');
      if (additionalNames.isEmpty) {
        log.info('[$contextName]');
      } else {
        log.info('[$contextName] ... or ${additionalNames.join(', ')}');
      }

      for (final enumValue in detectedContexts[i]) {
        log.info(' - $enumValue');
      }
    }
  }

  return resultMap;
}

List<_DetectedContext> _digestEntry(
  List<String> keyParts,
  String value,
  Map<String, dynamic> resultMap,
) {
  final basePath = keyParts.join('.');
  List<BracketRange> brackets = BracketsUtils.findTopLevelBrackets(value);
  if (brackets.length == 1 &&
      brackets.first.start == 0 &&
      brackets.first.end == value.length - 1) {
    // potential single complex node
    // we check [BracketsUtils] beforehand for better performance
    final singleComplexMatch = RegexUtils.arbComplexNode.firstMatch(value);
    if (singleComplexMatch != null) {
      // this is a plural or a context node
      // add additional nodes to this base path

      final variable = singleComplexMatch.group(1)!.trim();
      final type = singleComplexMatch.group(2)!.trim();
      final content = singleComplexMatch.group(3)!;
      final enumValues = type == 'select' ? <String>{} : null;
      final isPlural = type == 'plural';
      for (final part in RegexUtils.arbComplexNodeContent.allMatches(content)) {
        final partName =
            isPlural ? _digestPluralKey(part.group(1)!) : part.group(1)!;
        final partContent = part.group(2)!;
        MapUtils.addItemToMap(
          map: resultMap,
          destinationPath: '$basePath(param=$variable).$partName',
          item: _digestLeafText(partContent),
        );
        if (enumValues != null) {
          enumValues.add(partName);
        }
      }
      if (enumValues != null) {
        return [_DetectedContext(variable, enumValues)];
      } else {
        return [];
      }
    }
  }

  final nameFactory = _DistinctNameFactory();
  final detectedContexts = <_DetectedContext>[];
  String result = value;
  bool modified = false;
  while (brackets.isNotEmpty) {
    final currentBracket = brackets.first;

    final match =
        RegexUtils.arbComplexNode.firstMatch(currentBracket.substring());

    if (match == null) {
      // invalid bracket, continue to next bracket without any changes
      brackets.removeAt(0);
      continue;
    }

    // add linked complex expression
    final originalParameter = match.group(1)!.trim();
    final parameter = nameFactory.getNewName(originalParameter);
    final content = match.group(0)!;
    final currPath = keyParts
        .replaceLast('${keyParts.last}${parameter.toCase(CaseStyle.pascal)}');

    final contextResult = _digestEntry(currPath, content, resultMap);
    detectedContexts.addAll(contextResult);

    // update string
    result = currentBracket
        .replaceWith('@:$basePath${parameter.toCase(CaseStyle.pascal)}');

    // re-run because indices changed (old bracket list is invalid now)
    brackets = BracketsUtils.findTopLevelBrackets(result);

    modified = true;
  }

  if (!modified) {
    // simple node
    MapUtils.addItemToMap(
      map: resultMap,
      destinationPath: basePath,
      item: _digestLeafText(value),
    );
    return [];
  }

  // contains complex nodes
  MapUtils.addItemToMap(
    map: resultMap,
    destinationPath: basePath,
    item: _digestLeafText(result),
  );

  return detectedContexts;
}

/// Transforms arguments to camel case
/// Adds 'arg' to every positional argument
String _digestLeafText(String text) {
  return text.replaceBracesInterpolation(replacer: (match) {
    final param = match.substring(1, match.length - 1);
    final number = int.tryParse(param);
    if (number != null) {
      return '{arg$number}';
    } else {
      return '{${param.toCase(CaseStyle.camel)}}';
    }
  });
}

/// ARB files use '=0', '=1', and '=2' for 'zero', 'one', and 'two'
/// We need to normalize that.
String _digestPluralKey(String key) {
  switch (key) {
    case '=0':
      return 'zero';
    case '=1':
      return 'one';
    case '=2':
      return 'two';
    default:
      return key;
  }
}

void _digestMeta(
  List<String> keyParts,
  Map<String, dynamic> value,
  Map<String, dynamic> resultMap,
) {
  final description = value['description'] as String?;
  if (description == null) {
    return;
  }

  final String path;
  if (keyParts.length == 1) {
    path = '@${keyParts.last}'.toLowerCase();
  } else {
    path =
        '${keyParts.sublist(0, keyParts.length - 1).join('.')}.@${keyParts.last}';
  }

  MapUtils.addItemToMap(
    map: resultMap,
    destinationPath: path,
    item: description,
  );
}

class _DetectedContext {
  final String contextName;
  final Set<String> contextEnum;

  _DetectedContext(this.contextName, this.contextEnum);
}

String _contextNameWithSuffix(String contextName, String suffix) {
  return '$contextName$suffix'.toCase(CaseStyle.pascal);
}

extension on List<String> {
  /// Replace last element with another, returns the new list
  List<String> replaceLast(String replace) {
    final copy = [...this];
    copy[length - 1] = replace;
    return copy;
  }
}

class _DistinctNameFactory {
  final existingNames = <String>{};

  /// Gets a name which is distinct from the previous ones
  /// If [raw] already exists, then a number will be appended
  ///
  /// E.g.
  /// apple, banana, apple2, apple3, banana2, ...
  String getNewName(String raw) {
    int number = 1;
    String result = raw;
    while (existingNames.contains(result)) {
      number++;
      result = raw + number.toString();
    }
    existingNames.add(result);
    return result;
  }
}
