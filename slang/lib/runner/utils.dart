import 'dart:io';

import 'package:slang/builder/builder/raw_config_builder.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/translation_file.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';

/// This collection contains all relevant files to process.
class SlangFileCollection {
  /// Config specified in build.yaml, slang.yaml
  final RawConfig config;

  /// Files containing translations
  final List<File> files;

  SlangFileCollection({
    required this.config,
    required this.files,
  });

  List<TranslationFile> get translationFiles {
    String currentDirectory = Directory.current.path.replaceAll('\\', '/');
    if (!currentDirectory.endsWith('/')) {
      currentDirectory += '/';
    }
    return files.map((f) {
      return TranslationFile(
        path: f.path.replaceAll('\\', '/').replaceAll(currentDirectory, ''),
        read: () => File(f.path).readAsString(),
      );
    }).toList();
  }
}

Future<SlangFileCollection> readFileCollection({
  required bool verbose,
}) async {
  // config file must be in top-level directory
  final topLevelFiles =
      Directory.current.listSync(recursive: false).whereType<File>().toList();

  final config = await getConfig(topLevelFiles, verbose);

  List<FileSystemEntity> files;
  if (config.inputDirectory != null) {
    files = Directory(config.inputDirectory!)
        .listSync(recursive: true)
        .whereType<File>()
        .toList();
  } else {
    files = FileUtils.getFilesBreadthFirst(
      rootDirectory: Directory.current,
      ignoreTopLevelDirectories: {
        '.fvm',
        '.flutter.git',
        '.dart_tool',
        'build',
        'ios',
        'android',
        'web',
      },
    );
  }

  return SlangFileCollection(
    config: config,
    files: files
        .where((file) => file.path.endsWith(config.inputFilePattern))
        .cast<File>()
        .toList(),
  );
}

Future<RawConfig> getConfig(
  List<FileSystemEntity> files,
  bool verbose,
) async {
  RawConfig? config;
  for (final file in files) {
    final fileName = file.path.getFileName();

    if (fileName == 'slang.yaml') {
      final content = await File(file.path).readAsString();
      config = RawConfigBuilder.fromYaml(content, true);
      if (config != null) {
        if (verbose) {
          print('Found slang.yaml!');
        }
        break;
      }
    }

    if (fileName == 'build.yaml') {
      final content = await File(file.path).readAsString();
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

extension on String {
  /// converts /some/path/file.json to file.json
  String getFileName() {
    return PathUtils.getFileName(this);
  }
}
