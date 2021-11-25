import 'dart:io';

/// Operations on paths
/// Be aware that builder always uses '/' and therefore it may fail on Windows systems
class PathUtils {
  /// converts /some/path/file.json to file.json
  static String getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  /// converts /some/path/file.json to file
  static String getFileNameNoExtension(String path) {
    return getFileName(path).split('.').first;
  }

  /// converts /some/path/file.i18n.json to i18n.json
  static String getFileExtension(String path) {
    final fileName = getFileName(path);
    final firstDot = fileName.indexOf('.');
    return fileName.substring(firstDot + 1);
  }
}
