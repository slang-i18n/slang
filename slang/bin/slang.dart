import 'dart:io';

import 'package:slang/builder/builder/raw_config_builder.dart';
import 'package:slang/builder/builder/translation_map_builder.dart';
import 'package:slang/builder/generator_facade.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/translation_file.dart';
import 'package:slang/runner/analyze.dart';
import 'package:slang/runner/apply.dart';
import 'package:slang/runner/stats.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';

/// Determines what the runner will do
enum RunnerMode {
  generate, // default
  watch, // generate on change
  stats, // print translation stats
  analyze, // generate missing translations
  apply, // apply translations from analyze
}

/// To run this:
/// -> flutter pub run slang
///
/// Scans translation files and builds the dart file.
/// This is usually faster than the build_runner implementation.
void main(List<String> arguments) async {
  final RunnerMode mode;
  final bool verbose;
  if (arguments.isNotEmpty) {
    switch (arguments[0]) {
      case 'watch':
        mode = RunnerMode.watch;
        break;
      case 'stats':
        mode = RunnerMode.stats;
        break;
      case 'analyze':
        mode = RunnerMode.analyze;
        break;
      case 'apply':
        mode = RunnerMode.apply;
        break;
      default:
        mode = RunnerMode.generate;
    }
    verbose = mode == RunnerMode.generate ||
        mode == RunnerMode.watch ||
        (arguments.length == 2 &&
            (arguments[1] == '-v' || arguments[1] == '--verbose'));
  } else {
    mode = RunnerMode.generate;
    verbose = true;
  }

  switch (mode) {
    case RunnerMode.generate:
    case RunnerMode.watch:
      print('Generating translations...\n');
      break;
    case RunnerMode.stats:
    case RunnerMode.analyze:
      print('Scanning translations...\n');
      break;
    case RunnerMode.apply:
      print('Applying translations...\n');
      break;
  }

  final stopwatch = Stopwatch();
  if (mode != RunnerMode.watch) {
    // only run stopwatch if generating once
    stopwatch.start();
  }

  // config file must be in top-level directory
  final topLevelFiles =
      Directory.current.listSync(recursive: false).whereType<File>();

  final config = await getConfig(topLevelFiles.toList(), verbose);

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

  // filter files according to file pattern
  files = files
      .where((file) => file.path.endsWith(config.inputFilePattern))
      .toList();

  // the actual runner
  switch (mode) {
    case RunnerMode.apply:
      await runApplyTranslations(rawConfig: config, arguments: arguments);
      break;
    case RunnerMode.watch:
      await watchTranslations(config: config, files: files);
      break;
    case RunnerMode.generate:
    case RunnerMode.stats:
    case RunnerMode.analyze:
      await generateTranslations(
        mode: mode,
        rawConfig: config,
        files: files,
        verbose: verbose,
        stopwatch: stopwatch,
        arguments: arguments,
      );
      break;
  }
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

Future<void> watchTranslations({
  required RawConfig config,
  required List<FileSystemEntity> files,
}) async {
  final inputDirectoryPath = config.inputDirectory;
  if (inputDirectoryPath == null) {
    print('Please set input_directory in build.yaml.');
    return;
  }

  final inputDirectory = Directory(inputDirectoryPath);
  final stream = inputDirectory.watch(events: FileSystemEvent.all);

  await generateTranslations(
    mode: RunnerMode.watch,
    rawConfig: config,
    files: files,
    verbose: false,
  );

  print('Listening to changes in $inputDirectoryPath (non-recursive)');
  stdout.write('\r -> Init at $currentTime.');
  await for (final event in stream) {
    if (event.path.endsWith(config.inputFilePattern)) {
      stdout.write('\r -> Generating...           ');
      final newFiles = inputDirectory
          .listSync(recursive: true)
          .where((item) =>
              item is File && item.path.endsWith(config.inputFilePattern))
          .toList();
      await generateTranslations(
        mode: RunnerMode.watch,
        rawConfig: config,
        files: newFiles,
        verbose: false,
      );
      stdout.write('\r -> Last Update at $currentTime.');
    }
  }
}

/// Reads the translations from hard drive and generates the g.dart file
/// The [files] are already filtered (only translation files!).
Future<void> generateTranslations({
  required RunnerMode mode,
  required RawConfig rawConfig,
  required List<FileSystemEntity> files,
  required bool verbose,
  Stopwatch? stopwatch,
  List<String>? arguments,
}) async {
  if (files.isEmpty) {
    print('No translation file found.');
    return;
  }

  // STEP 1: determine base name and output file name / path
  final String outputFilePath;

  if (rawConfig.outputDirectory != null) {
    // output directory specified, use this path instead
    outputFilePath = rawConfig.outputDirectory! +
        Platform.pathSeparator +
        rawConfig.outputFileName;
  } else {
    // use the directory of the first (random) translation file
    final fileName = files.first.path.getFileName();
    outputFilePath =
        files.first.path.replaceAll("${Platform.pathSeparator}$fileName", '') +
            Platform.pathSeparator +
            rawConfig.outputFileName;
  }

  // STEP 2: scan translations
  if (verbose) {
    print('Scanning translations...');
    print('');
  }

  final translationMap = await TranslationMapBuilder.build(
    rawConfig: rawConfig,
    files: files
        .map((f) => TranslationFile(
              path: f.path.replaceAll('\\', '/'),
              read: () => File(f.path).readAsString(),
            ))
        .toList(),
    verbose: verbose,
  );

  if (mode == RunnerMode.stats) {
    getStats(
      rawConfig: rawConfig,
      translationMap: translationMap,
    ).printResult();
    if (stopwatch != null) {
      print('');
      print('Scan done. (${stopwatch.elapsed})');
    }
    return; // skip generation
  } else if (mode == RunnerMode.analyze) {
    analyzeTranslations(
      rawConfig: rawConfig,
      translationMap: translationMap,
      arguments: arguments ?? [],
    );
    if (stopwatch != null) {
      print('Analysis done. (${stopwatch.elapsed})');
    }
    return; // skip generation
  }

  // STEP 3: generate .g.dart content
  final result = GeneratorFacade.generate(
    rawConfig: rawConfig,
    baseName: rawConfig.outputFileName.getFileNameNoExtension(),
    translationMap: translationMap,
  );

  // STEP 4: write output to hard drive
  FileUtils.createMissingFolders(filePath: outputFilePath);
  if (rawConfig.outputFormat == OutputFormat.singleFile) {
    // single file
    FileUtils.writeFile(
      path: outputFilePath,
      content: result.joinAsSingleOutput(),
    );
  } else {
    // multiple files
    FileUtils.writeFile(
      path: BuildResultPaths.mainPath(outputFilePath),
      content: result.header,
    );
    for (final entry in result.translations.entries) {
      final locale = entry.key;
      final localeTranslations = entry.value;
      FileUtils.writeFile(
        path: BuildResultPaths.localePath(
          outputPath: outputFilePath,
          locale: locale,
          pathSeparator: Platform.pathSeparator,
        ),
        content: localeTranslations,
      );
    }
    if (result.flatMap != null) {
      FileUtils.writeFile(
        path: BuildResultPaths.flatMapPath(
          outputPath: outputFilePath,
          pathSeparator: Platform.pathSeparator,
        ),
        content: result.flatMap!,
      );
    }
  }

  if (verbose) {
    print('');
    if (rawConfig.outputFormat == OutputFormat.singleFile) {
      print('Output: $outputFilePath');
    } else {
      print('Output:');
      print(' -> $outputFilePath');
      for (final locale in result.translations.keys) {
        print(' -> ${BuildResultPaths.localePath(
          outputPath: outputFilePath,
          locale: locale,
          pathSeparator: Platform.pathSeparator,
        )}');
      }
      if (result.flatMap != null) {
        print(' -> ${BuildResultPaths.flatMapPath(
          outputPath: outputFilePath,
          pathSeparator: Platform.pathSeparator,
        )}');
      }
      print('');
    }

    if (stopwatch != null) {
      print('Translations generated successfully. (${stopwatch.elapsed})');
    }
  }
}

// returns current time in HH:mm:ss
String get currentTime {
  final now = DateTime.now();
  return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
}

extension on String {
  /// converts /some/path/file.json to file.json
  String getFileName() {
    return PathUtils.getFileName(this);
  }

  /// converts /some/path/file.json to file
  String getFileNameNoExtension() {
    return PathUtils.getFileNameNoExtension(this);
  }
}
