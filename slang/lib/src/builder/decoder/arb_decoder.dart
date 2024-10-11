import 'dart:convert';

import 'package:slang/src/builder/decoder/base_decoder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/utils/brackets_utils.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';
import 'package:slang/src/builder/utils/string_interpolation_extensions.dart';

class ArbDecoder extends BaseDecoder {
  @override
  Map<String, dynamic> decode(String raw) {
    final sourceMap = json.decode(raw) as Map<String, dynamic>;

    final entryMetadata = <String, _EntryMetadata>{}; // key -> metadata

    // Parse metadata first
    for (final key in sourceMap.keys) {
      final value = sourceMap[key];
      if (key.length > 1 &&
          key.startsWith('@') &&
          value is Map<String, dynamic>) {
        entryMetadata[key.substring(1)] = _EntryMetadata.parseEntry(
          value,
        );
      }
    }

    final resultMap = <String, dynamic>{};

    for (final key in sourceMap.keys) {
      if (key.startsWith('@')) {
        continue;
      }

      final metadata = entryMetadata[key] ??
          const _EntryMetadata(
            description: null,
            paramTypeMap: {},
          );

      final value = sourceMap[key];

      _addEntry(
        key: key,
        metadata: metadata,
        value: value,
        resultMap: resultMap,
      );

      if (metadata.description != null) {
        resultMap['@$key'] = metadata.description;
      }
    }

    return resultMap;
  }
}

void _addEntry({
  required final String key,
  required final _EntryMetadata metadata,
  required final String value,
  required final Map<String, dynamic> resultMap,
}) {
  List<BracketRange> brackets = BracketsUtils.findTopLevelBrackets(value);
  if (brackets.length == 1 &&
      brackets.first.start == 0 &&
      brackets.first.end == value.length - 1) {
    // potential single complex node
    final singleComplexMatch = RegexUtils.arbComplexNode.firstMatch(value);
    if (singleComplexMatch != null) {
      // this is a plural or a context node
      // add additional nodes to this base path

      final variable = singleComplexMatch.group(1)!.trim();
      final type = singleComplexMatch.group(2)!.trim();
      final content = singleComplexMatch.group(3)!;
      final isPlural = type == 'plural';
      for (final part in RegexUtils.arbComplexNodeContent.allMatches(content)) {
        final partName =
            isPlural ? _digestPluralKey(part.group(1)!) : part.group(1)!;
        final partContent = part.group(2)!;
        MapUtils.addItemToMap(
          map: resultMap,
          destinationPath:
              '$key(${isPlural ? 'plural' : 'context=${variable.toCase(CaseStyle.pascal)}'}, param=$variable).$partName',
          item: _digestLeafText(partContent, metadata.paramTypeMap),
        );
      }
      return;
    }
  }

  final nameFactory = _DistinctNameFactory();
  String result = value;
  while (brackets.isNotEmpty) {
    final currentBracket = brackets.first;

    final match =
        RegexUtils.arbComplexNode.firstMatch(currentBracket.substring());

    if (match == null) {
      // invalid complex, continue to next bracket without any changes
      // Likely just a placeholder for a variable
      brackets.removeAt(0);
      continue;
    }

    // add linked complex expression
    final originalParameter = match.group(1)!.trim();
    final parameter = nameFactory.getNewName(originalParameter);

    // create new key
    _addEntry(
      key: '${key}__$parameter',
      metadata: metadata,
      value: match.group(0)!,
      resultMap: resultMap,
    );

    // update string and refer to new key
    result = currentBracket.replaceWith('@:${key}__$parameter');

    // re-run because indices changed (old bracket list is invalid now)
    brackets = BracketsUtils.findTopLevelBrackets(result);
  }

  resultMap[key] = _digestLeafText(result, metadata.paramTypeMap);
}

/// Transforms arguments to camel case
/// Adds 'arg' to every positional argument
String _digestLeafText(String text, Map<String, String> paramTypeMap) {
  return text.replaceBracesInterpolation(replacer: (match) {
    final param = match.substring(1, match.length - 1);
    final paramType =
        paramTypeMap[param] != null ? ': ${paramTypeMap[param]}' : '';
    final number = int.tryParse(param);
    if (number != null) {
      return '{arg$number$paramType}';
    } else {
      return '{${param.toCase(CaseStyle.camel)}$paramType}';
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

class _EntryMetadata {
  final String? description;
  final Map<String, String> paramTypeMap;

  const _EntryMetadata({
    required this.description,
    required this.paramTypeMap,
  });

  static _EntryMetadata parseEntry(Map<String, dynamic> map) {
    final description = map['description'] as String?;

    final placeholders = map['placeholders'] as Map<String, dynamic>?;
    if (placeholders == null) {
      return _EntryMetadata(
        description: description,
        paramTypeMap: {},
      );
    }

    final paramTypeMap = <String, String>{};
    for (final key in placeholders.keys) {
      final value = placeholders[key] as Map<String, dynamic>;
      final type = value['type'] as String?;
      if (type != null) {
        paramTypeMap[key] = type;
      }
    }

    return _EntryMetadata(
      description: description,
      paramTypeMap: paramTypeMap,
    );
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
