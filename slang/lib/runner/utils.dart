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
    return files
        .map((f) => TranslationFile(
              path: f.path.replaceAll('\\', '/'),
              read: () => File(f.path).readAsString(),
            ))
        .toList();
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
          print('Found slang.yaml in ${file.path}');
        }
        break;
      }
    }

    if (fileName == 'build.yaml') {
      final content = await File(file.path).readAsString();
      config = RawConfigBuilder.fromYaml(content);
      if (config != null) {
        if (verbose) {
          print('Found build.yaml in ${file.path}');
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

  // convert to absolute paths
  config = config.withAbsolutePaths();

  // show build config
  if (verbose && !useDefaultConfig) {
    print('');
    config.printConfig();
    print('');
  }

  config.validate();

  return config;
}

extension on RawConfig {
  RawConfig withAbsolutePaths() {
    return RawConfig(
      baseLocale: baseLocale,
      fallbackStrategy: fallbackStrategy,
      inputDirectory: inputDirectory?.toAbsolutePath(),
      inputFilePattern: inputFilePattern,
      outputDirectory: outputDirectory?.toAbsolutePath(),
      outputFileName: outputFileName,
      outputFormat: outputFormat,
      localeHandling: localeHandling,
      flutterIntegration: flutterIntegration,
      namespaces: namespaces,
      translateVar: translateVar,
      enumName: enumName,
      translationClassVisibility: translationClassVisibility,
      keyCase: keyCase,
      keyMapCase: keyMapCase,
      paramCase: paramCase,
      stringInterpolation: stringInterpolation,
      renderFlatMap: renderFlatMap,
      translationOverrides: translationOverrides,
      renderTimestamp: renderTimestamp,
      maps: maps,
      pluralAuto: pluralAuto,
      pluralParameter: pluralParameter,
      pluralCardinal: pluralCardinal,
      pluralOrdinal: pluralOrdinal,
      contexts: contexts,
      interfaces: interfaces,
      imports: imports,
    );
  }
}

extension on String {
  /// converts /some/path/file.json to file.json
  String getFileName() {
    return PathUtils.getFileName(this);
  }
}
