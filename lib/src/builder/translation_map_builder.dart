import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/utils/yaml_utils.dart';
import 'package:yaml/yaml.dart';

class TranslationMapBuilder {
  /// Parses the raw string and builds the map based on the tree
  /// in the translation file.
  /// No case transformations, etc! Only the raw data represented as a tree.
  static Map<String, dynamic> fromString(FileType fileType, String raw) {
    switch (fileType) {
      case FileType.json:
        return json.decode(raw);
      case FileType.yaml:
        return YamlUtils.deepCast(loadYaml(raw));
      case FileType.csv:
        return _fromCSV(raw);
    }
  }

  /// True, if this csv contains at least 3 rows
  static bool isCompactCSV(String raw) {
    final parsed = const CsvToListConverter().convert(raw);
    return parsed.first.length > 2;
  }

  /// Parses the csv content
  /// If this csv is a compact csv, then the root keys represents the locale names
  static Map<String, dynamic> _fromCSV(String raw) {
    final compactCSV = isCompactCSV(raw);
    final parsed = const CsvToListConverter().convert(raw);
    final result = <String, dynamic>{};

    if (compactCSV) {
      final locales = <String>[];
      for (final locale in parsed.first) {
        locales.add(locale);
      }
      locales.removeAt(0); // remove the first locale because it is the key

      for (final locale in locales) {
        // add the defined locales as root entries
        result[locale] = <String, dynamic>{};
      }

      for (int rowIndex = 1; rowIndex < parsed.length; rowIndex++) {
        // start at second row
        final row = parsed[rowIndex];
        if (row.length != locales.length + 1) {
          throw 'CSV row at index $rowIndex must have ${locales.length + 1} columns but only has ${row.length}.';
        }

        for (int localeIndex = 0; localeIndex < locales.length; localeIndex++) {
          final locale = locales[localeIndex];
          _addStringToMap(
            map: result[locale],
            destinationPath: parsed[rowIndex][0],
            leafContent: parsed[rowIndex][localeIndex + 1],
          );
        }
      }
      return result;
    } else {
      // normal csv
      for (final row in parsed) {
        _addStringToMap(
          map: result,
          destinationPath: row[0],
          leafContent: row[1],
        );
      }
      return result;
    }
  }

  /// Adds a string (leaf) to the map at the specified path
  static void _addStringToMap({
    required Map<String, dynamic> map,
    required String destinationPath,
    required String leafContent,
  }) {
    final pathList = destinationPath.split('.');
    Map<String, dynamic> curr = map;
    for (int i = 0; i < pathList.length; i++) {
      final subPath = pathList[i];
      if (i == pathList.length - 1) {
        // destination
        curr[subPath] = leafContent;
      } else {
        // make sure that the path to the leaf exists
        if (curr.containsKey(subPath)) {
          if (!(curr[subPath] is Map<String, dynamic>)) {
            throw 'The leaf "$destinationPath" cannot be added because "$subPath" is already specified as a leaf.';
          }
        } else {
          curr[subPath] = <String, dynamic>{};
        }
        curr = curr[subPath];
      }
    }
  }
}
