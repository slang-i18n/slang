import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:json2yaml/json2yaml.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/utils/path_utils.dart';

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
    final String encodedContent;
    if (fileType == FileType.yaml) {
      if (content.containsKey(INFO_KEY)) {
        // workaround
        // https://github.com/alexei-sintotski/json2yaml/issues/23
        content = {
          '"$INFO_KEY"': content[INFO_KEY],
          ...content..remove(INFO_KEY),
        };
      }
      encodedContent = json2yaml(content, yamlStyle: YamlStyle.generic);
    } else {
      encodedContent = JsonEncoder.withIndent('  ').convert(content);
    }

    FileUtils.writeFile(
      path: path,
      content: encodedContent,
    );
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

  /// Returns all files in directory.
  /// Also scans sub directories using the breadth-first approach.
  static List<File> getFilesBreadthFirst({
    required Directory rootDirectory,
    required Set<String> ignoreTopLevelDirectories,
  }) {
    final result = <File>[];
    final queue = Queue<Directory>();
    bool topLevel = true;
    queue.add(rootDirectory);

    do {
      final dirList = queue.removeFirst().listSync(recursive: false);
      for (final FileSystemEntity entity in dirList) {
        if (entity is File) {
          result.add(entity);
        } else if (entity is Directory) {
          final fileName = PathUtils.getFileName(entity.path);
          if (!topLevel || !ignoreTopLevelDirectories.contains(fileName)) {
            queue.add(entity);
          }
        }
      }
      topLevel = false;
    } while (queue.isNotEmpty);

    return result;
  }
}
