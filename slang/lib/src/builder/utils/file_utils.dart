import 'dart:convert';
import 'dart:io';

import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/utils/yaml_writer.dart';

const String infoKey = '@@info';

class FileUtils {
  static void writeFile({required String path, required String content}) {
    File(path).writeAsStringSync(content);
  }

  static void writeFileOfType({
    required FileType fileType,
    required String path,
    required Map<String, dynamic> content,
  }) {
    FileUtils.writeFile(
      path: path,
      content: FileUtils.encodeContent(
        fileType: fileType,
        content: content,
      ),
    );
  }

  static String encodeContent({
    required FileType fileType,
    required Map<String, dynamic> content,
  }) {
    switch (fileType) {
      case FileType.json:
        // this encoder does not append \n automatically
        return '${JsonEncoder.withIndent('  ').convert(content)}\n';
      case FileType.yaml:
        return convertToYaml(content);
      case FileType.csv:
        String escapeRow(String value) {
          final escaped = value.replaceAll('"', '""');
          if (escaped.contains(RegExp(r'[,"]'))) {
            return '"$escaped"';
          }
          return escaped;
        }

        void encodeCsvRows({
          String key = '',
          required dynamic value,
          required Map<String, String> result,
        }) {
          if (value is Map) {
            for (final k in value.keys) {
              final prefix = key.isEmpty ? '' : '$key.';
              encodeCsvRows(
                key: '$prefix$k',
                value: value[k],
                result: result,
              );
            }
          } else if (value is String) {
            result[key] = escapeRow(value);
          }
        }

        final Map<String, Map<String, String>> columns = {};
        if (content.containsKey(infoKey)) {
          final info = content.remove(infoKey);
          columns[infoKey] = {infoKey: escapeRow(info.join('\\n'))};
        }
        for (final e in content.entries) {
          final result = <String, String>{};
          encodeCsvRows(result: result, value: e.value);

          columns[e.key] = result;
        }

        // get all translation keys
        final translationKeys = columns.values
            .map((e) => e.entries.map((e) => e.key))
            .expand((e) => e)
            .toSet();

        final headers = ['key', ...columns.keys].join(',');
        final rows = translationKeys.map((key) {
          final values =
              columns.values.map((e) => e.containsKey(key) ? e[key] : '');
          return "$key,${values.join(',')}";
        });

        return "$headers\n${rows.join('\n')}";
      case FileType.arb:
        // this encoder does not append \n automatically
        return '${JsonEncoder.withIndent('  ').convert(content)}\n';
    }
  }

  static void createMissingFolders({required String filePath}) {
    final index = filePath
        .replaceAll('/', Platform.pathSeparator)
        .replaceAll('\\', Platform.pathSeparator)
        .lastIndexOf(Platform.pathSeparator);
    if (index == -1) {
      return;
    }

    final directoryPath = filePath.substring(0, index);
    Directory(directoryPath).createSync(recursive: true);
  }
}
