import 'package:slang/src/builder/builder/translation_map_builder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/utils/file_utils.dart';
import 'package:slang/src/builder/utils/path_utils.dart';
import 'package:slang/src/runner/utils/format.dart';
import 'package:slang/src/utils/log.dart' as log;
import 'package:slang/src/utils/stopwatch.dart';

/// Reads the translations from hard drive and generates the g.dart file
Future<void> generateTranslations({
  required SlangFileCollection fileCollection,
  Stopwatch? stopwatch,
}) async {
  if (fileCollection.files.isEmpty) {
    log.error('No translation file found.');
    return;
  }

  // STEP 1: determine base name and output file name / path
  final outputFilePath = fileCollection.determineOutputPath();

  // STEP 2: scan translations
  log.verbose('Scanning translations...\n');

  final translationMap = await TranslationMapBuilder.build(
    fileCollection: fileCollection,
  );

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

  if (log.level == log.Level.verbose) {
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
    if (log.level == log.Level.verbose) {
      log.verbose('\nFormatting "$formatDir" ...');
      if (stopwatch != null) {
        formatStopwatch = Stopwatch()..start();
      }
    }
    await runDartFormat(
      dir: formatDir,
      width: fileCollection.config.format.width,
    );
    if (formatStopwatch != null) {
      log.verbose('Format done. ${formatStopwatch.elapsedSeconds}');
    }
  }

  if (stopwatch != null) {
    if (log.level == log.Level.verbose) {
      log.verbose('');
    }
    log.info(
        '${_green}Translations generated successfully. ${stopwatch.elapsedSeconds}$_reset');
  }
}

const _green = '\x1B[32m';
const _reset = '\x1B[0m';
