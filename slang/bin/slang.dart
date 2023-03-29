import 'dart:io';

import 'package:slang/builder/builder/translation_map_builder.dart';
import 'package:slang/builder/generator_facade.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/translation_file.dart';
import 'package:slang/runner/analyze.dart';
import 'package:slang/runner/apply.dart';
import 'package:slang/runner/migrate.dart';
import 'package:slang/runner/outdated.dart';
import 'package:slang/runner/stats.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';
import 'package:slang/runner/utils.dart';
import 'package:watcher/watcher.dart';

/// Determines what the runner will do
enum RunnerMode {
  generate, // default
  watch, // generate on change
  stats, // print translation stats
  analyze, // generate missing translations
  apply, // apply translations from analyze
  migrate, // migration tool
  outdated, // add 'OUTDATED' modifier to secondary locales
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
      case 'migrate':
        mode = RunnerMode.migrate;
        break;
      case 'outdated':
        mode = RunnerMode.outdated;
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
    case RunnerMode.migrate:
      break;
    case RunnerMode.outdated:
      print('Adding "OUTDATED" flag...');
      break;
  }

  final stopwatch = Stopwatch();
  if (mode != RunnerMode.watch) {
    // only run stopwatch if generating once
    stopwatch.start();
  }

  final fileCollection = await readFileCollection(verbose: verbose);

  // the actual runner
  final filteredArguments = arguments.skip(1).toList();
  switch (mode) {
    case RunnerMode.apply:
      await runApplyTranslations(
        fileCollection: fileCollection,
        arguments: filteredArguments,
      );
      break;
    case RunnerMode.watch:
      await watchTranslations(fileCollection.config);
      break;
    case RunnerMode.generate:
    case RunnerMode.stats:
    case RunnerMode.analyze:
      await generateTranslations(
        mode: mode,
        rawConfig: fileCollection.config,
        files: fileCollection.translationFiles,
        verbose: verbose,
        stopwatch: stopwatch,
        arguments: filteredArguments,
      );
      break;
    case RunnerMode.migrate:
      await runMigrate(filteredArguments);
      break;
    case RunnerMode.outdated:
      await runOutdated(
        fileCollection: fileCollection,
        arguments: filteredArguments,
      );
      break;
  }
}

Future<void> watchTranslations(RawConfig config) async {
  final inputDirectoryPath = config.inputDirectory;
  if (inputDirectoryPath == null) {
    print('Please set input_directory in build.yaml or slang.yaml.');
    return;
  }

  final inputDirectory = Directory(inputDirectoryPath);
  final stream = Watcher(inputDirectoryPath).events;

  print('Listening to changes in $inputDirectoryPath');
  _generateTranslationsFromWatch(
    config: config,
    inputDirectory: inputDirectory,
    counter: 1,
    fileName: '',
  );
  int counter = 2;
  await for (final event in stream) {
    if (event.path.endsWith(config.inputFilePattern)) {
      _generateTranslationsFromWatch(
        config: config,
        inputDirectory: inputDirectory,
        counter: counter,
        fileName: event.path.getFileName(),
      );
      counter++;
    }
  }
}

Future<void> _generateTranslationsFromWatch({
  required RawConfig config,
  required Directory inputDirectory,
  required int counter,
  required String fileName,
}) async {
  final stopwatch = Stopwatch()..start();
  _printDynamicLastLine('\r[$currentTime] $_YELLOW#$counter Generating...');

  final newFiles = inputDirectory
      .listSync(recursive: true)
      .where(
          (item) => item is File && item.path.endsWith(config.inputFilePattern))
      .map((f) => TranslationFile(
            path: f.path.replaceAll('\\', '/'),
            read: () => File(f.path).readAsString(),
          ))
      .toList();

  bool success = true;
  try {
    await generateTranslations(
      mode: RunnerMode.watch,
      rawConfig: config,
      files: newFiles,
      verbose: false,
    );
  } catch (e) {
    success = false;
    print('');
    print(e);
    _printDynamicLastLine(
      '\r[$currentTime] $_RED#$counter Error ${stopwatch.elapsedSeconds}',
    );
  }

  if (success) {
    if (counter == 1) {
      _printDynamicLastLine(
          '\r[$currentTime] $_GREEN#1 Init ${stopwatch.elapsedSeconds}');
    } else {
      _printDynamicLastLine(
        '\r[$currentTime] $_GREEN#$counter Update $fileName ${stopwatch.elapsedSeconds}',
      );
    }
  }
}

/// Reads the translations from hard drive and generates the g.dart file
/// The [files] are already filtered (only translation files!).
Future<void> generateTranslations({
  required RunnerMode mode,
  required RawConfig rawConfig,
  required List<TranslationFile> files,
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
    final translationFilePath = files.first.path;
    if (rawConfig.flutterIntegration &&
        !translationFilePath
            .contains('${Directory.current.path.replaceAll('\\', '/')}/lib')) {
      // In Flutter environment, only files inside 'lib' matter
      // Generate to lib/gen/<fileName> by default.
      outputFilePath = Directory.current.path +
          Platform.pathSeparator +
          'lib' +
          Platform.pathSeparator +
          'gen' +
          Platform.pathSeparator +
          rawConfig.outputFileName;
    } else {
      outputFilePath = PathUtils.replaceFileName(
        path: translationFilePath,
        newFileName: rawConfig.outputFileName,
        pathSeparator: '/',
      );
    }
  }

  // STEP 2: scan translations
  if (verbose) {
    print('Scanning translations...');
    print('');
  }

  final translationMap = await TranslationMapBuilder.build(
    rawConfig: rawConfig,
    files: files,
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
    runAnalyzeTranslations(
      rawConfig: rawConfig,
      translationMap: translationMap,
      arguments: arguments ?? [],
    );
    if (stopwatch != null) {
      print('Analysis done. ${stopwatch.elapsedSeconds}');
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
      print(
          '${_GREEN}Translations generated successfully. ${stopwatch.elapsedSeconds}$_RESET');
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

String? _lastPrint;

void _printDynamicLastLine(String output) {
  if (_lastPrint == null) {
    stdout.write('\r$output$_RESET');
  } else {
    stdout.write('\r${output.padRight(_lastPrint!.length, ' ')}$_RESET');
  }
  _lastPrint = output;
}

const _GREEN = '\x1B[32m';
const _YELLOW = '\x1B[33m';
const _RED = '\x1B[31m';
const _RESET = '\x1B[0m';

extension on Stopwatch {
  String get elapsedSeconds {
    return '(${elapsed.inMilliseconds / 1000} seconds)';
  }
}
