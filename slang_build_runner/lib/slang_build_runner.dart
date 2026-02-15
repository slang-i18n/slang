import 'dart:async';
import 'dart:convert';

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

  I18nBuilder({required this.config});

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': ['_slang_temp.json'],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final findAssetsPattern = config.inputDirectory != null
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

    // STEP 4: Encode all outputs into a single file
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
      pageWidth: config.format.width,
    );

    final preparedOutput = {
      BuildResultPaths.mainPath(outputFilePath):
          result.main.formatted(config, formatter),
      for (final entry in result.translations.entries)
        BuildResultPaths.localePath(
          outputPath: outputFilePath,
          locale: entry.key,
        ): entry.value.formatted(config, formatter),
    };

    final tempId = AssetId(buildStep.inputId.package, 'lib/_slang_temp.json');
    await buildStep.writeAsString(tempId, jsonEncode(preparedOutput));
  }
}

PostProcessBuilder i18nPostProcessBuilder(BuilderOptions options) {
  return I18nPostProcessBuilder();
}

class I18nPostProcessBuilder implements PostProcessBuilder {
  @override
  final inputExtensions = ['_slang_temp.json'];

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    final content = await buildStep.readInputAsString();

    final Map<String, String> outputs =
        jsonDecode(content).cast<String, String>();

    // for (final entry in outputs.entries) {
    //   print('Writing to ${entry.key}');
    //   buildStep.writeAsString(
    //     AssetId(buildStep.inputId.package, entry.key),
    //     entry.value,
    //   );
    // }

    /// TODO: buildStep.writeAsString somehow does not produce any files. We use dart:io for now.
    FileUtils.createMissingFolders(filePath: outputs.keys.first);

    for (final entry in outputs.entries) {
      FileUtils.writeFile(
        path: entry.key,
        content: entry.value,
      );
    }

    buildStep.deletePrimaryInput();
  }
}

extension on String {
  /// Conditionally formats the string using the provided [formatter].
  String formatted(RawConfig config, DartFormatter formatter) {
    return switch (config.format.enabled) {
      true => formatter.format(this),
      false => this,
    };
  }
}
