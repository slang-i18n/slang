import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/src/builder/builder/raw_config_builder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/utils/path_utils.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/utils/log.dart' as log;

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
          'cargokit_build',
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
    bool showWarning = true,
  }) {
    // True, if (1) namespaces are enabled and (2) directory locale is used
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

            if (!config.namespaces) {
              final localeMatch =
                  RegexUtils.localeRegex.firstMatch(fileNameNoExtension);
              if (localeMatch != null) {
                final locale = I18nLocale(
                  language: localeMatch.group(1)!,
                  script: localeMatch.group(2),
                  country: localeMatch.group(3),
                );

                return TranslationFile(
                  path: f.path,
                  locale: locale,
                  namespace: TranslationFile.DEFAULT_NAMESPACE,
                  read: f.read,
                );
              }
            }

            final baseFileMatch =
                RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);
            if (includeUnderscore || baseFileMatch != null) {
              // base file (file without locale)
              // could also be a non-base locale when directory name is a locale (namespace only)

              // directory name could be a locale
              I18nLocale? directoryLocale;
              if (config.namespaces) {
                directoryLocale = PathUtils.findDirectoryLocale(
                  filePath: f.path,
                  inputDirectory: config.inputDirectory,
                );

                if (showWarning && directoryLocale == null) {
                  _baseLocaleDeprecationWarning(
                    fileName: PathUtils.getFileName(f.path),
                    replacement:
                        '${fileNameNoExtension}_${config.baseLocale.languageTag.replaceAll('-', '_')}${config.inputFilePattern}',
                  );
                }
              }

              if (showWarning &&
                  !config.namespaces &&
                  config.fileType != FileType.csv) {
                // Note: Compact CSV files are still allowed to have a file name without locale.
                _namespaceDeprecationWarning(
                  fileName: PathUtils.getFileName(f.path),
                  replacement:
                      '${config.baseLocale.languageTag.replaceAll('-', '_')}${config.inputFilePattern}',
                );
              }

              return TranslationFile(
                path: f.path,
                locale: directoryLocale ?? config.baseLocale,
                namespace: config.namespaces
                    ? fileNameNoExtension
                    : TranslationFile.DEFAULT_NAMESPACE,
                read: f.read,
              );
            }

            // secondary files (strings_x)
            final match =
                RegexUtils.fileWithLocaleRegex.firstMatch(fileNameNoExtension);
            if (match != null) {
              final namespace = match.group(1)!;
              final locale = I18nLocale(
                language: match.group(2)!,
                script: match.group(3),
                country: match.group(4),
              );

              if (showWarning && !config.namespaces) {
                _namespaceDeprecationWarning(
                  fileName: PathUtils.getFileName(f.path),
                  replacement:
                      '${locale.languageTag.replaceAll('-', '_')}${config.inputFilePattern}',
                );
              }

              return TranslationFile(
                path: f.path,
                locale: locale,
                namespace: config.namespaces
                    ? namespace
                    : TranslationFile.DEFAULT_NAMESPACE,
                read: f.read,
              );
            }

            return null;
          })
          .nonNulls
          .sortedBy((file) => '${file.locale}-${file.namespace}'),
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
          log.verbose('Found slang.yaml!');
        }
        break;
      }
    }

    if (fileName == 'build.yaml') {
      final content = File(file.path).readAsStringSync();
      config = RawConfigBuilder.fromYaml(content);
      if (config != null) {
        if (verbose) {
          log.verbose('Found build.yaml!');
        }
        break;
      }
    }
  }

  final useDefaultConfig = config == null;
  if (config == null) {
    config = RawConfigBuilder.fromMap({});
    if (verbose) {
      log.verbose('No build.yaml or slang.yaml, using default settings.');
    }
  }

  // show build config
  if (verbose && !useDefaultConfig) {
    log.verbose('');
    config.printConfig();
    log.verbose('');
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

void _namespaceDeprecationWarning({
  required String fileName,
  required String replacement,
}) {
  log.error(
    'DEPRECATED(v4.3.0): Do not use namespaces in file names when namespaces are disabled: "$fileName" -> "$replacement"',
  );
}

void _baseLocaleDeprecationWarning({
  required String fileName,
  required String replacement,
}) {
  log.error(
    'DEPRECATED(v4.3.0): Always specify locale: "$fileName" -> "$replacement"',
  );
}
