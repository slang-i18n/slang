import 'dart:async';

import 'package:build/build.dart';
import 'package:slang/builder/builder/raw_config_builder.dart';
import 'package:slang/builder/builder/translation_map_builder.dart';
import 'package:slang/builder/generator_facade.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/translation_file.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/map_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';
import 'package:glob/glob.dart';

/// Static entry point for build_runner
Builder i18nBuilder(BuilderOptions options) {
  return I18nBuilder(
    config: RawConfigBuilder.fromMap(MapUtils.deepCast(options.config))
      ..validate(),
  );
}

class I18nBuilder implements Builder {
  final RawConfig config;
  final String outputFilePattern;
  bool _generated = false;

  I18nBuilder({required this.config})
      : this.outputFilePattern = config.outputFileName.getFileExtension();

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // only generate once
    if (_generated) return;

    _generated = true;

    final Glob findAssetsPattern = config.inputDirectory != null
        ? Glob('**${config.inputDirectory}/**${config.inputFilePattern}')
        : Glob('**${config.inputFilePattern}');

    // STEP 1: determine base name and output file name / path

    final assets = await buildStep.findAssets(findAssetsPattern).toList();
    final String outputFilePath;

    // CAUTION: in build_runner, the path separator seems to be hard coded to /
    if (config.outputDirectory != null) {
      // output directory specified, use this path instead
      outputFilePath = config.outputDirectory! + '/' + config.outputFileName;
    } else {
      // use the directory of the first (random) translation file
      final translationFilePath = assets.first.pathSegments;
      if (config.flutterIntegration && !translationFilePath.contains('lib')) {
        // In Flutter environment, only files inside 'lib' matter
        // Generate to lib/gen/<fileName> by default.
        outputFilePath = 'lib/gen/${config.outputFileName}';
      } else {
        final finalOutputDirectory =
        (assets.first.pathSegments..removeLast()).join('/');
        outputFilePath = '$finalOutputDirectory/${config.outputFileName}';
      }
    }

    // STEP 2: scan translations
    final translationMap = await TranslationMapBuilder.build(
      rawConfig: config,
      files: assets
          .map((f) => TranslationFile(
                path: f.path,
                read: () => buildStep.readAsString(f),
              ))
          .toList(),
      verbose: false,
    );

    // STEP 3: generate .g.dart content
    final result = GeneratorFacade.generate(
      rawConfig: config,
      baseName: config.outputFileName.getFileNameNoExtension(),
      translationMap: translationMap,
    );

    // STEP 4: write output to hard drive
    FileUtils.createMissingFolders(filePath: outputFilePath.toAbsolutePath());
    if (config.outputFormat == OutputFormat.singleFile) {
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
            pathSeparator: '/',
          ),
          content: localeTranslations,
        );
      }
      if (result.flatMap != null) {
        FileUtils.writeFile(
          path: BuildResultPaths.flatMapPath(
            outputPath: outputFilePath,
            pathSeparator: '/',
          ),
          content: result.flatMap!,
        );
      }
    }
  }

  @override
  get buildExtensions => {
        config.inputFilePattern: [outputFilePattern],
      };
}

extension on String {
  /// converts /some/path/file.json to file
  String getFileNameNoExtension() {
    return PathUtils.getFileNameNoExtension(this);
  }

  /// converts /some/path/file.i18n.json to i18n.json
  String getFileExtension() {
    return PathUtils.getFileExtension(this);
  }
}
