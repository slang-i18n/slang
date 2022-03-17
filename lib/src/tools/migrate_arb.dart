import 'dart:convert';
import 'dart:io';

import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/utils/file_utils.dart';
import 'package:fast_i18n/src/utils/regex_utils.dart';
import 'package:fast_i18n/src/utils/string_extensions.dart';

Future<void> migrateArb(String sourcePath, String destinationPath) async {
  print('Migrating ARB to JSON...');

  final source = await File(sourcePath).readAsString();
  final resultMap = _migrateArb(source);

  FileUtils.createMissingFolders(filePath: destinationPath);
  FileUtils.writeFile(
    path: destinationPath,
    content: JsonEncoder.withIndent('  ').convert(resultMap),
  );

  print('');
  print(
      'Please don\'t forget to configure the correct string_interpolation in build.yaml');
  print('');
  print('File generated: ${destinationPath.toAbsolutePath()}');
}

Map<String, dynamic> _migrateArb(String raw) {
  final sourceMap = json.decode(raw);
  final resultMap = <String, dynamic>{};

  if (sourceMap is! Map<String, dynamic>) {
    throw 'ARB files must be a JSON object';
  }

  List<Set<String>> detectedContexts = [];
  List<String> detectedContextNames = []; // index matches with detectedContexts

  sourceMap.forEach((key, value) {
    if (key.startsWith('@@')) {
      TranslationMapBuilder.addStringToMap(
        map: resultMap,
        destinationPath: key,
        leafContent: value,
      );
      return;
    }
    final bool isMeta = key.startsWith('@');
    if (isMeta) {
      key = key.substring(1);
    }

    final keyParts = key.getWords();
    if (isMeta) {
      _digestMeta(
          keyParts, value is Map<String, dynamic> ? value : {}, resultMap);
    } else {
      final detectedContext = _digestEntry(keyParts, value, resultMap);
      if (detectedContext != null &&
          detectedContexts.every((c) => c != detectedContext.contextEnum)) {
        // detected new context
        detectedContexts.add(detectedContext.contextEnum);
        detectedContextNames.add(detectedContext.contextName);
      }
    }
  });

  if (detectedContexts.isNotEmpty) {
    print('');
    print('Detected contexts (please define them in build.yaml):');
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

      print('');
      if (additionalNames.isEmpty) {
        print('[$contextName]');
      } else {
        print('[$contextName] ... or ${additionalNames.join(', ')}');
      }

      detectedContexts[i].forEach((enumValue) {
        print(' - $enumValue');
      });
    }
  }

  return resultMap;
}

_DetectedContext? _digestEntry(
    List<String> keyParts, String value, Map<String, dynamic> resultMap) {
  final basePath = keyParts.join('.').toLowerCase();
  final pluralOrContext = RegexUtils.arbComplexNode.firstMatch(value);
  if (pluralOrContext != null) {
    // this is a plural or a context node
    // add additional nodes to this base path

    final variable = pluralOrContext.group(1)!.trim();
    final type = pluralOrContext.group(3)!.trim();
    final content = pluralOrContext.group(5)!;
    final enumValues = type == 'select' ? <String>{} : null;
    for (final part in RegexUtils.arbComplexNodeContent.allMatches(content)) {
      final partName = part.group(1)!;
      final partContent = part.group(2)!;
      TranslationMapBuilder.addStringToMap(
        map: resultMap,
        destinationPath: '$basePath($variable).$partName',
        leafContent: partContent,
      );
      if (enumValues != null) {
        enumValues.add(partName);
      }
    }
    if (enumValues != null) {
      return _DetectedContext(variable, enumValues);
    } else {
      return null;
    }
  } else {
    // simple node
    TranslationMapBuilder.addStringToMap(
      map: resultMap,
      destinationPath: basePath,
      leafContent: value,
    );
    return null;
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
  final path =
      '${keyParts.sublist(0, keyParts.length - 1).join('.')}.@${keyParts.last}'
          .toLowerCase();
  TranslationMapBuilder.addStringToMap(
    map: resultMap,
    destinationPath: path,
    leafContent: description,
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
