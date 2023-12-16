import 'dart:convert';
import 'dart:io';

import 'package:json2yaml/json2yaml.dart';
import 'package:slang/builder/model/enums.dart';

const String INFO_KEY = '@@info';

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
        return JsonEncoder.withIndent('  ').convert(content) + '\n';
      case FileType.yaml:
        if (content.containsKey(INFO_KEY)) {
          // workaround
          // https://github.com/alexei-sintotski/json2yaml/issues/23
          content = {
            '"$INFO_KEY"': content[INFO_KEY],
            ...content..remove(INFO_KEY),
          };
        }
        return json2yaml(content, yamlStyle: YamlStyle.generic);
      case FileType.csv:
        throw UnimplementedError('CSV is not supported yet');
      case FileType.arb:
        // this encoder does not append \n automatically
        return JsonEncoder.withIndent('  ').convert(content) + '\n';
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
