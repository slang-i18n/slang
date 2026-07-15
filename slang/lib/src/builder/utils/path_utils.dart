import 'package:collection/collection.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';

/// Operations on paths
class PathUtils {
  /// converts /some/path/file.json to file.json
  static String getFileName(String path) {
    return path.replaceAll('\\', '/').split('/').last;
  }

  /// converts /some/path/file.json to file
  static String getFileNameNoExtension(String path) {
    return getFileName(path).split('.').first;
  }

  /// converts /some/path/file.i18n.json to i18n.json
  static String getFileExtension(String path) {
    final fileName = getFileName(path);
    final firstDot = fileName.lastIndexOf('.');
    return fileName.substring(firstDot + 1);
  }

  /// converts /some/path/file.slang.dart to slang.dart
  /// (everything after the first dot; complements [getFileNameNoExtension])
  static String getFullFileExtension(String path) {
    final fileName = getFileName(path);
    final firstDot = fileName.indexOf('.');
    if (firstDot == -1) {
      return '';
    }
    return fileName.substring(firstDot + 1);
  }

  /// converts /a/b/file.json to [a, b, file.json]
  static List<String> getPathSegments(String path) {
    return path
        .replaceAll('\\', '/')
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// converts /a/b/file.json to b
  static String? getParentDirectory(String path) {
    final segments = getPathSegments(path);
    if (segments.length == 1) {
      return null;
    }
    return segments[segments.length - 2];
  }

  /// Converts /a/b/file.json to /a/b
  static String? getParentPath(String path) {
    final segments = getPathSegments(path);
    if (segments.length == 1) {
      return null;
    }
    return segments.sublist(0, segments.length - 1).join('/');
  }

  /// finds locale in directory path
  /// eg. /en-US/b/file.json will result in en-US
  static DirectoryLocaleResult? findDirectoryLocale({
    required String filePath,
    required String? inputDirectory,
  }) {
    List<String> segments = PathUtils.getPathSegments(filePath);

    if (inputDirectory != null) {
      // locale is the first directory after inputDirectory
      final inputDirectorySegments = PathUtils.getPathSegments(inputDirectory);
      if (inputDirectorySegments.isNotEmpty &&
          inputDirectorySegments.firstOrNull == segments.firstOrNull &&
          segments.length > inputDirectorySegments.length) {
        final localeSegmentIndex = inputDirectorySegments.length;
        return DirectoryLocaleResult.tryFromSegment(
          segment: segments[localeSegmentIndex],
          localeSegmentIndex: localeSegmentIndex,
          namespacePrefix: segments.sublist(
            localeSegmentIndex + 1,
            segments.length - 1,
          ),
        );
      }
    } else if (segments.length >= 2) {
      // locale is the parent directory of the file
      final localeSegmentIndex = segments.length - 2;
      return DirectoryLocaleResult.tryFromSegment(
        segment: segments[localeSegmentIndex],
        localeSegmentIndex: localeSegmentIndex,
        namespacePrefix: const [],
      );
    }

    return null;
  }

  /// converts /some/path/file.json to /some/path/newFile.json
  static String replaceFileName({
    required String path,
    required String newFileName,
    required String pathSeparator,
  }) {
    final index = path.lastIndexOf(pathSeparator);
    if (index == -1) {
      return newFileName;
    } else {
      return path.substring(0, index + pathSeparator.length) + newFileName;
    }
  }

  /// converts /some/path to /some/path/my_file.json
  static String withFileName({
    required String directoryPath,
    required String fileName,
    required String pathSeparator,
  }) {
    if (directoryPath.endsWith(pathSeparator)) {
      return directoryPath + fileName;
    } else {
      return directoryPath + pathSeparator + fileName;
    }
  }
}

class DirectoryLocaleResult {
  final I18nLocale locale;

  /// The index of the locale segment in the path segments list.
  /// This is used to replace the locale segment
  /// when generating new paths for other locales.
  final int localeSegmentIndex;

  /// If the locale is not a direct parent directory,
  /// all segments between the input directory and the locale segment
  /// are considered as namespace prefix.
  final List<String> namespacePrefix;

  DirectoryLocaleResult({
    required this.locale,
    required this.localeSegmentIndex,
    required this.namespacePrefix,
  });

  /// Tries to parse the given [segment] as a locale.
  /// Returns null if the segment does not match the locale regex.
  static DirectoryLocaleResult? tryFromSegment({
    required String segment,
    required int localeSegmentIndex,
    required List<String> namespacePrefix,
  }) {
    final locale = I18nLocale.tryFromString(segment);
    if (locale == null) {
      return null;
    }
    return DirectoryLocaleResult(
      locale: locale,
      localeSegmentIndex: localeSegmentIndex,
      namespacePrefix: namespacePrefix,
    );
  }

  @override
  String toString() {
    return 'DirectoryLocaleResult($locale, $localeSegmentIndex, namespacePrefix: $namespacePrefix)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectoryLocaleResult &&
          runtimeType == other.runtimeType &&
          locale == other.locale &&
          localeSegmentIndex == other.localeSegmentIndex &&
          const ListEquality().equals(namespacePrefix, other.namespacePrefix);

  @override
  int get hashCode =>
      locale.hashCode ^
      localeSegmentIndex.hashCode ^
      const ListEquality().hash(namespacePrefix);
}

class BuildResultPaths {
  static String mainPath(String outputPath) {
    return outputPath;
  }

  static String localePath({
    required String outputPath,
    required I18nLocale locale,
  }) {
    final fileNameNoExtension = PathUtils.getFileNameNoExtension(outputPath);
    final extension = PathUtils.getFullFileExtension(outputPath);
    final localeExt = locale.languageTag.replaceAll('-', '_');
    final fileName = '${fileNameNoExtension}_$localeExt.$extension';
    return PathUtils.replaceFileName(
      path: outputPath,
      newFileName: fileName,
      pathSeparator: '/',
    );
  }

  static String flatMapPath({
    required String outputPath,
  }) {
    final fileNameNoExtension = PathUtils.getFileNameNoExtension(outputPath);
    final extension = PathUtils.getFullFileExtension(outputPath);
    final fileName = '${fileNameNoExtension}_map.$extension';
    return PathUtils.replaceFileName(
      path: outputPath,
      newFileName: fileName,
      pathSeparator: '/',
    );
  }
}
