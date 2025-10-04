import 'dart:async';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/builder/raw_config_builder.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/builder/slang_file_collection_builder.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/builder/translation_map_builder.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/generator_facade.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/model/raw_config.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/model/slang_file_collection.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/utils/file_utils.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/utils/map_utils.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/utils/path_utils.dart';

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
      : outputFilePattern = config.outputFileName.getFileExtension();

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
    final files = assets.map((f) {
      return PlainTranslationFile(
        path: f.path,
        read: () => buildStep.readAsString(f),
      );
    }).toList();

    final fileCollection = SlangFileCollectionBuilder.fromFileModel(
      config: config,
      files: files,
    );

    final outputFilePath = fileCollection.determineOutputPath();

    // STEP 2: scan translations
    final translationMap = await TranslationMapBuilder.build(
      fileCollection: fileCollection,
    );

    // STEP 3: generate .g.dart content
    final result = GeneratorFacade.generate(
      rawConfig: config,
      translationMap: translationMap,
      inputDirectoryHint: fileCollection.determineInputPath(),
    );

    // STEP 4: write output to hard drive
    FileUtils.createMissingFolders(filePath: outputFilePath);

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
      pageWidth: config.format.width,
    );

    FileUtils.writeFile(
      path: BuildResultPaths.mainPath(outputFilePath),
      content: result.main.formatted(config, formatter),
    );

    for (final entry in result.translations.entries) {
      final locale = entry.key;
      final localeTranslations = entry.value;
      FileUtils.writeFile(
        path: BuildResultPaths.localePath(
          outputPath: outputFilePath,
          locale: locale,
        ),
        content: localeTranslations.formatted(config, formatter),
      );
    }
  }

  @override
  get buildExtensions => {
        config.inputFilePattern: [outputFilePattern],
      };
}

extension on String {
  /// converts /some/path/file.i18n.json to i18n.json
  String getFileExtension() {
    return PathUtils.getFileExtension(this);
  }

  /// Conditionally formats the string using the provided [formatter].
  String formatted(RawConfig config, DartFormatter formatter) {
    return switch (config.format.enabled) {
      true => formatter.format(this),
      false => this,
    };
  }
}
