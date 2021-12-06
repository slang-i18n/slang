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
        if (row.length < locales.length + 1) {
          throw 'CSV row at index $rowIndex must have ${locales.length + 1} columns but only has ${row.length}.';
        }

        for (int localeIndex = 0; localeIndex < locales.length; localeIndex++) {
          final locale = locales[localeIndex];
          addStringToMap(
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
        addStringToMap(
          map: result,
          destinationPath: row[0],
          leafContent: row[1],
        );
      }
      return result;
    }
  }

  /// Adds a string (leaf) to the map at the specified path
  static void addStringToMap({
    required Map<String, dynamic> map,
    required String destinationPath,
    required String leafContent,
  }) {
    final pathList = destinationPath.split('.');
    dynamic curr = map; // may be a Map<String, dynamic> or List<dynamic>
    for (int i = 0; i < pathList.length; i++) {
      final subPath = pathList[i];
      final subPathInt = int.tryParse(subPath);

      final nextSubPath = i + 1 < pathList.length ? pathList[i + 1] : null;
      final nextIsList =
          nextSubPath != null ? int.tryParse(nextSubPath) != null : false;

      if (i == pathList.length - 1) {
        // destination
        if (subPathInt != null) {
          if (!(curr is List)) {
            throw 'The leaf "$destinationPath" cannot be added because the parent of "$subPathInt" is not a list.';
          }
          final added = addToList(
            list: curr,
            index: subPathInt,
            element: leafContent,
            overwrite: true,
          );

          if (!added) {
            throw 'The leaf "$destinationPath" cannot be added because there are missing indices.';
          }
        } else {
          if (!(curr is Map)) {
            throw 'The leaf "$destinationPath" cannot be added because the parent of "$subPath" is not a map.';
          }
          curr[subPath] = leafContent;
        }
      } else {
        // make sure that the path to the leaf exists
        if (subPathInt != null) {
          // list mode
          if (!(curr is List)) {
            throw 'The leaf "$destinationPath" cannot be added because the parent of "$subPathInt" is not a list.';
          }

          final added = addToList(
            list: curr,
            index: subPathInt,
            element: nextIsList ? <dynamic>[] : <String, dynamic>{},
            overwrite: false,
          );

          if (!added) {
            throw 'The leaf "$destinationPath" cannot be added because there are missing indices.';
          }

          curr = curr[subPathInt];
        } else {
          // map mode
          if (!(curr is Map)) {
            throw 'The leaf "$destinationPath" cannot be added because the parent of "$subPath" is not a map.';
          }

          if (!curr.containsKey(subPath)) {
            curr[subPath] = nextIsList ? <dynamic>[] : <String, dynamic>{};
          }

          curr = curr[subPath];
        }
      }
    }
  }

  /// Adds an element to the list
  /// Adding must be in the correct order, so if the list is too small, then it won't be added
  /// Returns true, if the element was added
  static bool addToList({
    required List list,
    required int index,
    required dynamic element,
    required bool overwrite,
  }) {
    if (list.length == index) {
      list.add(element);
      return true;
    } else if (overwrite && index < list.length) {
      list[index] = element;
      return true;
    } else {
      return false;
    }
  }
}
