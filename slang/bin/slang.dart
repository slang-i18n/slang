import 'dart:io';

import 'package:slang/builder/builder/build_config_builder.dart';
import 'package:slang/builder/builder/translation_map_builder.dart';
import 'package:slang/builder/generator_facade.dart';
import 'package:slang/builder/model/build_config.dart';
import 'package:slang/builder/model/translation_file.dart';
import 'package:slang/builder/stats_facade.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';

/// To run this:
/// -> flutter pub run slang
///
/// Scans translation files and builds the dart file.
/// This is usually faster than the build_runner implementation.
void main(List<String> arguments) async {
  final bool watchMode;
  final bool statsMode;
  final bool verbose;
  if (arguments.isNotEmpty) {
    watchMode = arguments[0] == 'watch';
    statsMode = arguments[0] == 'stats';
    verbose = !statsMode ||
        (arguments.length == 2 &&
            (arguments[1] == '-v' || arguments[1] == '--verbose'));
  } else {
    watchMode = false;
    statsMode = false;
    verbose = true;
  }

  if (statsMode) {
    print('Scanning translations...\n');
  } else {
    print('Generating translations...\n');
  }

  final stopwatch = Stopwatch();
  if (!watchMode) {
    // only run stopwatch if generating once
    stopwatch.start();
  }

  // get all files recursively (no directories)
  Iterable<FileSystemEntity> files =
      (await Directory.current.list(recursive: true).toList())
          .where((item) => FileSystemEntity.isFileSync(item.path));

  final buildConfig = await getBuildConfig(files, verbose);

  // filter files according to build config
  files = files.where((file) {
    if (!file.path.endsWith(buildConfig.inputFilePattern)) return false;

    if (buildConfig.inputDirectory != null &&
        !file.path.contains(buildConfig.inputDirectory!)) return false;

    return true;
  });

  if (watchMode) {
    await watchTranslations(buildConfig: buildConfig, files: files);
  } else {
    await generateTranslations(
      buildConfig: buildConfig,
      files: files,
      verbose: verbose,
      stopwatch: stopwatch,
      statsMode: statsMode,
    );
  }
}

Future<BuildConfig> getBuildConfig(
  Iterable<FileSystemEntity> files,
  bool verbose,
) async {
  BuildConfig? buildConfig;
  for (final file in files) {
    final fileName = file.path.getFileName();

    if (fileName == 'slang.yaml') {
      final content = await File(file.path).readAsString();
      buildConfig = BuildConfigBuilder.fromYaml(content, true);
      if (verbose) {
        print('Found slang.yaml in ${file.path}');
      }
      break;
    }

    if (fileName == 'build.yaml') {
      final content = await File(file.path).readAsString();
      buildConfig = BuildConfigBuilder.fromYaml(content);
      if (buildConfig != null) {
        if (verbose) {
          print('Found build.yaml in ${file.path}');
        }
        break;
      }
    }
  }

  if (buildConfig == null) {
    buildConfig = BuildConfigBuilder.fromMap({});
    if (verbose) {
      print('No build.yaml or slang.yaml, using default settings.');
    }
  }

  // convert to absolute paths
  buildConfig = buildConfig.withAbsolutePaths();

  // show build config
  if (verbose) {
    print('');
    buildConfig.printConfig();
    print('');
  }

  return buildConfig;
}

Future<void> watchTranslations({
  required BuildConfig buildConfig,
  required Iterable<FileSystemEntity> files,
}) async {
  final inputDirectoryPath = buildConfig.inputDirectory;
  if (inputDirectoryPath == null) {
    print('Please set input_directory in build.yaml.');
    return;
  }

  final inputDirectory = Directory(inputDirectoryPath);
  final stream = inputDirectory.watch(events: FileSystemEvent.all);

  await generateTranslations(
    buildConfig: buildConfig,
    files: files,
    verbose: false,
  );

  print('Listening to changes in $inputDirectoryPath (non-recursive)');
  stdout.write('\r -> Init at $currentTime.');
  await for (final event in stream) {
    if (event.path.endsWith(buildConfig.inputFilePattern)) {
      stdout.write('\r -> Generating...           ');
      final newFiles = (await inputDirectory.list().toList()).where((item) =>
          FileSystemEntity.isFileSync(item.path) &&
          item.path.endsWith(buildConfig.inputFilePattern));
      await generateTranslations(
        buildConfig: buildConfig,
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
  required BuildConfig buildConfig,
  required Iterable<FileSystemEntity> files,
  required bool verbose,
  Stopwatch? stopwatch,
  bool statsMode = false,
}) async {
  // STEP 1: determine base name and output file name / path
  final String outputFilePath;

  if (buildConfig.outputDirectory != null) {
    // output directory specified, use this path instead
    outputFilePath = buildConfig.outputDirectory! +
        Platform.pathSeparator +
        buildConfig.outputFileName;
  } else {
    // use the directory of the first (random) translation file
    final fileName = files.first.path.getFileName();
    outputFilePath =
        files.first.path.replaceAll("${Platform.pathSeparator}$fileName", '') +
            Platform.pathSeparator +
            buildConfig.outputFileName;
  }

  // STEP 2: scan translations
  if (verbose) {
    print('Scanning translations...');
    print('');
  }

  final translationMap = await TranslationMapBuilder.build(
    buildConfig: buildConfig,
    files: files
        .map((f) => TranslationFile(
              path: f.path.replaceAll('\\', '/'),
              read: () => File(f.path).readAsString(),
            ))
        .toList(),
    verbose: verbose,
  );

  // STATS MODE
  if (statsMode) {
    StatsFacade.parse(
      buildConfig: buildConfig,
      translationMap: translationMap,
    ).printResult();
    if (stopwatch != null) {
      print('');
      print('Scan done. (${stopwatch.elapsed})');
    }
    return; // skip generation
  }

  // STEP 3: generate .g.dart content
  final result = GeneratorFacade.generate(
    buildConfig: buildConfig,
    baseName: buildConfig.outputFileName.getFileNameNoExtension(),
    translationMap: translationMap,
  );

  // STEP 4: write output to hard drive
  FileUtils.createMissingFolders(filePath: outputFilePath);
  if (buildConfig.outputFormat == OutputFormat.singleFile) {
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
    if (buildConfig.outputFormat == OutputFormat.singleFile) {
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
