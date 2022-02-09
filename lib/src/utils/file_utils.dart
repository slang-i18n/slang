import 'dart:io';

class FileUtils {
  static void writeFile({required String path, required String content}) {
    File(path).writeAsStringSync(content);
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
