import 'dart:async';

import 'package:build/build.dart';
import 'package:slang/builder/builder/build_config_builder.dart';
import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/decoder/csv_decoder.dart';
import 'package:slang/builder/generator_facade.dart';
import 'package:slang/builder/model/build_config.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/namespace_translation_map.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/regex_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';
import 'package:slang/builder/utils/yaml_utils.dart';
import 'package:glob/glob.dart';

/// Static entry point for build_runner
Builder i18nBuilder(BuilderOptions options) {
  return I18nBuilder(
    buildConfig: BuildConfigBuilder.fromMap(YamlUtils.deepCast(options.config)),
  );
}

class I18nBuilder implements Builder {
  final BuildConfig buildConfig;
  final String outputFilePattern;
  bool _generated = false;

  I18nBuilder({required this.buildConfig})
      : this.outputFilePattern = buildConfig.outputFileName.getFileExtension();

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // only generate once
    if (_generated) return;

    _generated = true;

    final Glob findAssetsPattern = buildConfig.inputDirectory != null
        ? Glob(
            '**${buildConfig.inputDirectory}/**${buildConfig.inputFilePattern}')
        : Glob('**${buildConfig.inputFilePattern}');

    // STEP 1: determine base name and output file name / path

    final assets = await buildStep.findAssets(findAssetsPattern).toList();
    final String outputFilePath;

    // CAUTION: in build_runner, the path separator seems to be hard coded to /
    if (buildConfig.outputDirectory != null) {
      // output directory specified, use this path instead
      outputFilePath =
          buildConfig.outputDirectory! + '/' + buildConfig.outputFileName;
    } else {
      // use the directory of the first (random) translation file
      final finalOutputDirectory =
          (assets.first.pathSegments..removeLast()).join('/');
      outputFilePath = '$finalOutputDirectory/${buildConfig.outputFileName}';
    }

    // STEP 2: scan translations
    final translationMap = NamespaceTranslationMap();
    for (final asset in assets) {
      final content = await buildStep.readAsString(asset);
      final Map<String, dynamic> translations;
      try {
        translations = BaseDecoder.getDecoderOfFileType(buildConfig.fileType)
            .decode(content);
      } on FormatException catch (e) {
        throw 'File: ${asset.path}\n$e';
      }

      final fileNameNoExtension =
          asset.pathSegments.last.getFileNameNoExtension();
      final baseFileMatch =
          RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);
      if (baseFileMatch != null) {
        // base file
        final namespace = baseFileMatch.group(1)!;

        if (buildConfig.fileType == FileType.csv &&
            CsvDecoder.isCompactCSV(content)) {
          // compact csv

          translations.forEach((key, value) {
            final locale = I18nLocale.fromString(key);
            final localeTranslations = value as Map<String, dynamic>;
            translationMap.addTranslations(
              locale: locale,
              namespace: namespace,
              translations: localeTranslations,
            );
          });
        } else {
          // json, yaml or normal csv

          translationMap.addTranslations(
            locale: buildConfig.baseLocale,
            namespace: namespace,
            translations: translations,
          );
        }
      } else {
        // secondary files (strings_x)
        final match =
            RegexUtils.fileWithLocaleRegex.firstMatch(fileNameNoExtension);
        if (match != null) {
          final namespace = match.group(2)!;
          final language = match.group(3)!;
          final script = match.group(5);
          final country = match.group(7);
          final locale = I18nLocale(
            language: language,
            script: script,
            country: country,
          );

          translationMap.addTranslations(
            locale: locale,
            namespace: namespace,
            translations: translations,
          );
        }
      }
    }

    // STEP 3: generate .g.dart content
    final result = GeneratorFacade.generate(
      buildConfig: buildConfig,
      baseName: buildConfig.outputFileName.getFileNameNoExtension(),
      translationMap: translationMap,
    );

    // STEP 4: write output to hard drive
    FileUtils.createMissingFolders(filePath: outputFilePath.toAbsolutePath());
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
        buildConfig.inputFilePattern: [outputFilePattern],
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
