import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:slang/src/builder/decoder/base_decoder.dart';
import 'package:slang/src/builder/utils/map_utils.dart';

final _csvConverter = CsvToListConverter(
  // Allow both \r\n and \n
  // See README of csv package
  csvSettingsDetector: FirstOccurrenceSettingsDetector(
    eols: ['\r\n', '\n'],
    textDelimiters: ['"', "'"],
  ),
);

class CsvDecoder extends BaseDecoder {
  // If this csv is a compact csv, then the root keys represents the locale names
  @override
  Map<String, dynamic> decode(String raw) {
    final compactCSV = isCompactCSV(raw);
    final parsed = _csvConverter.convert(raw);

    if (compactCSV) {
      final result = <String, Map<String, dynamic>>{};
      final locales = <String?>[]; // list of locales or "comment"-locales

      for (final locale in parsed.first) {
        if (locale is! String) {
          throw 'The first row of the csv file should not contain numbers';
        }
        if (locale.startsWith('(')) {
          locales.add(null);
        } else {
          locales.add(locale);
        }
      }
      locales.removeAt(0); // remove the first locale because it is the key

      for (final locale in locales) {
        if (locale != null) {
          // add the defined locales as root entries
          result[locale] = <String, dynamic>{};
        }
      }

      for (int rowIndex = 1; rowIndex < parsed.length; rowIndex++) {
        // start at second row
        final row = parsed[rowIndex];
        if (row.length < locales.length + 1) {
          throw 'CSV row at index $rowIndex must have ${locales.length + 1} columns but only has ${row.length}.';
        }

        bool commentAdded = false;
        for (int localeIndex = 0; localeIndex < locales.length; localeIndex++) {
          final locale = locales[localeIndex];
          final path = parsed[rowIndex][0];
          final content = parsed[rowIndex][localeIndex + 1].toString();
          if (locale != null) {
            // normal column
            MapUtils.addItemToMap(
              map: result[locale]!,
              destinationPath: path,
              item: content,
            );
          } else if (!commentAdded && content.isNotEmpty) {
            // comment column (only parse the first comment column)
            // add @<path> for all other locales
            for (final localeMap in result.values) {
              final split = path.toString().split('.');
              split[split.length - 1] = '@${split[split.length - 1]}';
              MapUtils.addItemToMap(
                map: localeMap,
                destinationPath: split.join('.'),
                item: content,
              );
            }
            commentAdded = true;
          }
        }
      }
      return result;
    } else {
      // normal csv

      final result = <String, dynamic>{};
      for (final row in parsed) {
        MapUtils.addItemToMap(
          map: result,
          destinationPath: row[0],
          item: row[1].toString(),
        );
      }
      return result;
    }
  }

  /// True, if this csv contains at least 3 rows
  static bool isCompactCSV(String raw) {
    final parsed = _csvConverter.convert(raw);
    return parsed.first.length > 2;
  }
}
