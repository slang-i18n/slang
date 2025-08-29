import 'dart:io';

import 'package:slang/src/builder/builder/slang_file_collection_builder.dart';
import 'package:slang/src/builder/builder/translation_map_builder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/path_utils.dart';
import 'package:slang/src/runner/analyze.dart';
import 'package:slang/src/runner/apply.dart';
import 'package:slang/src/runner/clean.dart';
import 'package:slang/src/runner/configure.dart';
import 'package:slang/src/runner/edit.dart';
import 'package:slang/src/runner/help.dart';
import 'package:slang/src/runner/migrate.dart';
import 'package:slang/src/runner/normalize.dart';
import 'package:slang/src/runner/stats.dart';
import 'package:slang/src/runner/utils/format.dart';
import 'package:slang/src/utils/log.dart' as log;
import 'package:watcher/watcher.dart';

/// Determines what the runner will do
enum RunnerMode {
  generate, // default
  watch, // generate on change
  configure, // update configuration files
  stats, // print translation stats
  analyze, // generate missing translations
  apply, // apply translations from analyze
  migrate, // migration tool
  edit, // edit translations
  outdated, // add 'OUTDATED' modifier to secondary locales
  add, // add a translation
  clean, // clean unused translations
  normalize, // normalize translations according to base locale
}

/// To run this:
/// -> dart run slang
///
/// Scans translation files and builds the dart file.
/// This is usually faster than the build_runner implementation.
void main(List<String> arguments) async {
  final RunnerMode mode;
  log.Level logLevel = log.Level.normal;

  if (arguments.isNotEmpty) {
    if (const {'-h', '--help', 'help'}.contains(arguments[0])) {
      printHelp();
      return;
    }

    switch (arguments[0]) {
      case 'watch':
        mode = RunnerMode.watch;
        break;
      case 'configure':
        mode = RunnerMode.configure;
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
      case 'edit':
        mode = RunnerMode.edit;
        break;
      case 'outdated':
        mode = RunnerMode.outdated;
        break;
      case 'add':
        mode = RunnerMode.add;
        break;
      case 'clean':
        mode = RunnerMode.clean;
        break;
      case 'normalize':
        mode = RunnerMode.normalize;
        break;
      default:
        mode = RunnerMode.generate;
    }

    for (final arg in arguments) {
      if (arg == '-v' || arg == '--verbose') {
        logLevel = log.Level.verbose;
      }
    }
  } else {
    mode = RunnerMode.generate;
  }

  log.setLevel(logLevel);

  final verbose = logLevel == log.Level.verbose;

  switch (mode) {
    case RunnerMode.generate:
    case RunnerMode.watch:
      log.info('Generating translations...\n');
      break;
    case RunnerMode.configure:
      log.info('Configuring...\n');
      break;
    case RunnerMode.stats:
    case RunnerMode.analyze:
      log.info('Scanning translations...\n');
      break;
    case RunnerMode.apply:
      log.info('Applying translations...\n');
      break;
    case RunnerMode.migrate:
      break;
    case RunnerMode.edit:
      break;
    case RunnerMode.outdated:
      break;
    case RunnerMode.add:
      log.info('Adding translation...');
      break;
    case RunnerMode.clean:
      log.info('Removing unused translations...\n');
      break;
    case RunnerMode.normalize:
      log.info('Normalizing translations...\n');
      break;
  }

  final stopwatch = Stopwatch();
  if (mode != RunnerMode.watch) {
    // only run stopwatch if generating once
    stopwatch.start();
  }

  final fileCollection =
      SlangFileCollectionBuilder.readFromFileSystem(verbose: verbose);

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
    case RunnerMode.configure:
      runConfigure(
        fileCollection,
        arguments: filteredArguments,
      );
      break;
    case RunnerMode.generate:
    case RunnerMode.stats:
    case RunnerMode.analyze:
      await generateTranslations(
        mode: mode,
        fileCollection: fileCollection,
        verbose: verbose,
        stopwatch: stopwatch,
        arguments: filteredArguments,
      );
      break;
    case RunnerMode.migrate:
      await runMigrate(filteredArguments);
      break;
    case RunnerMode.edit:
      await runEdit(
        fileCollection: fileCollection,
        arguments: filteredArguments,
      );
      break;
    case RunnerMode.outdated:
      await runEdit(
        fileCollection: fileCollection,
        arguments: arguments,
      );
      break;
    case RunnerMode.add:
      await runEdit(
        fileCollection: fileCollection,
        arguments: arguments,
      );
      break;
    case RunnerMode.clean:
      await runClean(
        fileCollection: fileCollection,
        arguments: arguments,
      );
      break;
    case RunnerMode.normalize:
      await runNormalize(
        fileCollection: fileCollection,
        arguments: arguments,
      );
      break;
  }
}

Future<void> watchTranslations(RawConfig config) async {
  final inputDirectoryPath = config.inputDirectory;
  if (inputDirectoryPath == null) {
    log.error('Please set input_directory in build.yaml or slang.yaml.');
    return;
  }

  final inputDirectory = Directory(inputDirectoryPath);
  final stream = Watcher(inputDirectoryPath).events;

  log.info('Listening to changes in $inputDirectoryPath');
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
      .map((f) => PlainTranslationFile(
            path: f.path.replaceAll('\\', '/'),
            read: () => File(f.path).readAsString(),
          ))
      .toList();

  bool success = true;
  try {
    await generateTranslations(
      mode: RunnerMode.watch,
      fileCollection: SlangFileCollectionBuilder.fromFileModel(
        config: config,
        files: newFiles,
      ),
      verbose: false,
    );
  } catch (e) {
    success = false;
    log.error('\n${e.toString()}');
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
  required SlangFileCollection fileCollection,
  required bool verbose,
  Stopwatch? stopwatch,
  List<String>? arguments,
}) async {
  if (fileCollection.files.isEmpty) {
    log.error('No translation file found.');
    return;
  }

  // STEP 1: determine base name and output file name / path
  final outputFilePath = fileCollection.determineOutputPath();

  // STEP 2: scan translations
  if (verbose) {
    log.verbose('Scanning translations...\n');
  }

  final translationMap = await TranslationMapBuilder.build(
    fileCollection: fileCollection,
    verbose: verbose,
  );

  if (mode == RunnerMode.stats) {
    getStats(
      rawConfig: fileCollection.config,
      translationMap: translationMap,
    ).printResult();
    if (stopwatch != null) {
      log.info('\nScan done. (${stopwatch.elapsed})');
    }
    return; // skip generation
  } else if (mode == RunnerMode.analyze) {
    runAnalyzeTranslations(
      rawConfig: fileCollection.config,
      translationMap: translationMap,
      arguments: arguments ?? [],
    );
    if (stopwatch != null) {
      log.info('Analysis done. ${stopwatch.elapsedSeconds}');
    }
    return; // skip generation
  }

  // STEP 3: generate .g.dart content
  final result = GeneratorFacade.generate(
    rawConfig: fileCollection.config,
    translationMap: translationMap,
    inputDirectoryHint: fileCollection.determineInputPath(),
  );

  // STEP 4: write output to hard drive
  FileUtils.createMissingFolders(filePath: outputFilePath);

  FileUtils.writeFile(
    path: BuildResultPaths.mainPath(outputFilePath),
    content: result.main,
  );
  for (final entry in result.translations.entries) {
    final locale = entry.key;
    final localeTranslations = entry.value;
    FileUtils.writeFile(
      path: BuildResultPaths.localePath(
        outputPath: outputFilePath,
        locale: locale,
      ),
      content: localeTranslations,
    );
  }

  if (verbose) {
    log.verbose('\nOutput:');
    log.verbose(' -> $outputFilePath');
    for (final locale in result.translations.keys) {
      log.verbose(' -> ${BuildResultPaths.localePath(
        outputPath: outputFilePath,
        locale: locale,
      )}');
    }
  }

  if (fileCollection.config.format.enabled) {
    final formatDir = PathUtils.getParentPath(outputFilePath)!;
    Stopwatch? formatStopwatch;
    if (verbose) {
      log.verbose('\nFormatting "$formatDir" ...');
      if (stopwatch != null) {
        formatStopwatch = Stopwatch()..start();
      }
    }
    await runDartFormat(
      dir: formatDir,
      width: fileCollection.config.format.width,
    );
    if (verbose && formatStopwatch != null) {
      log.verbose('Format done. ${formatStopwatch.elapsedSeconds}');
    }
  }

  if (verbose && stopwatch != null) {
    log.verbose(
        '\n${_GREEN}Translations generated successfully. ${stopwatch.elapsedSeconds}$_RESET');
  } else if (stopwatch != null) {
    log.info(
        '${_GREEN}Translations generated successfully. ${stopwatch.elapsedSeconds}$_RESET');
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
}

String? _lastPrint;

void _printDynamicLastLine(String output) {
  if (_lastPrint == null) {
    log.write('\r$output$_RESET');
  } else {
    log.write('\r${output.padRight(_lastPrint!.length, ' ')}$_RESET');
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
