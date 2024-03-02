import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/builder/builder/raw_config_builder.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/utils/path_utils.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';

class SlangFileCollectionBuilder {
  static SlangFileCollection readFromFileSystem({
    required bool verbose,
  }) {
    // config file must be in top-level directory
    final topLevelFiles =
        Directory.current.listSync(recursive: false).whereType<File>().toList();

    final config = readConfigFromFileSystem(
      files: topLevelFiles,
      verbose: verbose,
    );

    final List<File> files;
    if (config.inputDirectory != null) {
      files = Directory(config.inputDirectory!)
          .listSync(recursive: true)
          .whereType<File>()
          .toList();
    } else {
      files = _getFilesBreadthFirst(
        rootDirectory: Directory.current,
        ignoreTopLevelDirectories: {
          'build',
          'ios',
          'android',
          'web',
          'macos',
          'linux',
          'windows',
          'test',
        },
        ignoreDirectories: {
          '.fvm',
          '.flutter.git',
          '.dart_tool',
          '.symlinks',
        },
      );
    }

    String currentDirectory = Directory.current.path.replaceAll('\\', '/');
    if (!currentDirectory.endsWith('/')) {
      currentDirectory += '/';
    }

    return fromFileModel(
      config: config,
      files:
          files.where((f) => f.path.endsWith(config.inputFilePattern)).map((f) {
        return PlainTranslationFile(
          path: f.path.replaceAll('\\', '/').replaceAll(currentDirectory, ''),
          read: () async => f.readAsStringSync(),
        );
      }),
    );
  }

  static SlangFileCollection fromFileModel({
    required RawConfig config,
    required Iterable<PlainTranslationFile> files,
  }) {
    final includeUnderscore = config.namespaces &&
        files.any((f) {
          final fileNameNoExtension = PathUtils.getFileNameNoExtension(f.path);
          final baseFileMatch =
              RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);
          if (baseFileMatch == null) {
            return false;
          }

          // It is a file without locale but has a directory locale
          return PathUtils.findDirectoryLocale(
                filePath: f.path,
                inputDirectory: config.inputDirectory,
              ) !=
              null;
        });

    return SlangFileCollection(
      config: config,
      files: files
          .map((f) {
            final fileNameNoExtension =
                PathUtils.getFileNameNoExtension(f.path);
            final baseFileMatch =
                RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);
            if (includeUnderscore || baseFileMatch != null) {
              // base file (file without locale, may be multiples due to namespaces!)
              // could also be a non-base locale when directory name is a locale

              // directory name could be a locale
              I18nLocale? directoryLocale;
              if (config.namespaces) {
                directoryLocale = PathUtils.findDirectoryLocale(
                  filePath: f.path,
                  inputDirectory: config.inputDirectory,
                );
              }

              return TranslationFile(
                path: f.path,
                locale: directoryLocale ?? config.baseLocale,
                namespace: fileNameNoExtension,
                read: f.read,
              );
            } else {
              // secondary files (strings_x)
              final match = RegexUtils.fileWithLocaleRegex
                  .firstMatch(fileNameNoExtension);
              if (match != null) {
                final namespace = match.group(1)!;
                final locale = I18nLocale(
                  language: match.group(2)!,
                  script: match.group(3),
                  country: match.group(4),
                );

                return TranslationFile(
                  path: f.path,
                  locale: locale,
                  namespace: namespace,
                  read: f.read,
                );
              }
            }

            return null;
          })
          .whereNotNull()
          .toList(),
    );
  }
}

RawConfig readConfigFromFileSystem({
  required List<File> files,
  required bool verbose,
}) {
  RawConfig? config;
  for (final file in files) {
    final fileName = file.path.getFileName();

    if (fileName == 'slang.yaml') {
      final content = File(file.path).readAsStringSync();
      config = RawConfigBuilder.fromYaml(content, true);
      if (config != null) {
        if (verbose) {
          print('Found slang.yaml!');
        }
        break;
      }
    }

    if (fileName == 'build.yaml') {
      final content = File(file.path).readAsStringSync();
      config = RawConfigBuilder.fromYaml(content);
      if (config != null) {
        if (verbose) {
          print('Found build.yaml!');
        }
        break;
      }
    }
  }

  final useDefaultConfig = config == null;
  if (config == null) {
    config = RawConfigBuilder.fromMap({});
    if (verbose) {
      print('No build.yaml or slang.yaml, using default settings.');
    }
  }

  // show build config
  if (verbose && !useDefaultConfig) {
    print('');
    config.printConfig();
    print('');
  }

  config.validate();

  return config;
}

/// Returns all files in directory.
/// Also scans sub directories using the breadth-first approach.
List<File> _getFilesBreadthFirst({
  required Directory rootDirectory,
  required Set<String> ignoreTopLevelDirectories,
  required Set<String> ignoreDirectories,
}) {
  final result = <File>[];
  final queue = Queue<Directory>();
  bool topLevel = true;
  queue.add(rootDirectory);

  do {
    final dirList = queue.removeFirst().listSync(
          recursive: false,
          followLinks: false,
        );
    for (final FileSystemEntity entity in dirList) {
      if (entity is File) {
        result.add(entity);
      } else if (entity is Directory) {
        final fileName = PathUtils.getFileName(entity.path);
        if (topLevel && ignoreTopLevelDirectories.contains(fileName)) {
          continue;
        }

        if (ignoreDirectories.contains(fileName)) {
          continue;
        }

        queue.add(entity);
      }
    }
    topLevel = false;
  } while (queue.isNotEmpty);

  return result;
}

extension on String {
  /// converts /some/path/file.json to file.json
  String getFileName() {
    return PathUtils.getFileName(this);
  }
}
