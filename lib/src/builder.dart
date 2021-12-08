import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:fast_i18n/src/builder/build_config_builder.dart';
import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:fast_i18n/src/generator/generator_facade.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/namespace_translation_map.dart';
import 'package:fast_i18n/src/utils/regex_utils.dart';
import 'package:fast_i18n/src/utils/path_utils.dart';
import 'package:fast_i18n/src/utils/yaml_utils.dart';
import 'package:glob/glob.dart';

/// Static entry point for build_runner
Builder i18nBuilder(BuilderOptions options) {
  final buildConfig =
      BuildConfigBuilder.fromMap(YamlUtils.deepCast(options.config));
  String outputFilePattern;
  if (buildConfig.outputFileName != null) {
    // new variant
    outputFilePattern = buildConfig.outputFileName!.getFileExtension();
  } else {
    // legacy variant
    outputFilePattern = buildConfig.outputFilePattern;
  }
  return I18nBuilder(
    buildConfig: buildConfig,
    outputFilePattern: outputFilePattern,
  );
}

class I18nBuilder implements Builder {
  final BuildConfig buildConfig;
  final String outputFilePattern;
  bool _generated = false;

  I18nBuilder({required this.buildConfig, required this.outputFilePattern});

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

    final assets = <AssetId>[];
    String? baseName;
    String? outputFileName;
    String outputFilePath;

    if (buildConfig.outputFileName != null) {
      // newer version
      outputFileName = buildConfig.outputFileName!;
      baseName = buildConfig.outputFileName!.getFileNameNoExtension();
    }

    await buildStep.findAssets(findAssetsPattern).forEach((assetId) {
      assets.add(assetId);

      if (buildConfig.outputFileName == null) {
        // use legacy mode by taking the namespace name
        final fileNameNoExtension =
            assetId.pathSegments.last.getFileNameNoExtension();
        final baseFile =
            RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);
        if (baseFile != null) {
          // base file
          baseName = fileNameNoExtension;
          outputFileName = fileNameNoExtension + buildConfig.outputFilePattern;
        }
      }
    });

    if (baseName == null || outputFileName == null) {
      print('Error: No base translation file.');
      return;
    }

    // CAUTION: in build_runner, the path separator seems to be hard coded to /
    if (buildConfig.outputDirectory != null) {
      // output directory specified, use this path instead
      outputFilePath = buildConfig.outputDirectory! + '/' + outputFileName!;
    } else {
      // use the directory of the first (random) translation file
      final finalOutputDirectory =
          (assets.first.pathSegments..removeLast()).join('/');
      outputFilePath = '$finalOutputDirectory/$outputFileName';
    }

    // STEP 2: scan translations
    final translationMap = NamespaceTranslationMap();
    for (final asset in assets) {
      final content = await buildStep.readAsString(asset);
      final fileNameNoExtension =
          asset.pathSegments.last.getFileNameNoExtension();
      final baseFileMatch =
          RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);
      if (baseFileMatch != null) {
        // base file
        final namespace = baseFileMatch.group(1)!;

        if (buildConfig.fileType == FileType.csv &&
            TranslationMapBuilder.isCompactCSV(content)) {
          // compact csv

          final translations = TranslationMapBuilder.fromString(
            FileType.csv,
            content,
          );

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
            translations: TranslationMapBuilder.fromString(
              buildConfig.fileType,
              content,
            ),
          );
        }
      } else {
        // secondary files (strings_x)
        final match =
            RegexUtils.fileWithLocaleRegex.firstMatch(fileNameNoExtension);
        if (match != null) {
          final namespace = match.group(2)!;
          final language = match.group(3);
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
            translations: TranslationMapBuilder.fromString(
              buildConfig.fileType,
              content,
            ),
          );
        }
      }
    }

    // STEP 3: generate .g.dart content
    final result = GeneratorFacade.generate(
      buildConfig: buildConfig,
      baseName: baseName!,
      translationMap: translationMap,
    );

    // STEP 4: write output to hard drive
    File(outputFilePath).writeAsStringSync(result);

    if (buildConfig.outputFileName == null && buildConfig.namespaces) {
      print('');
      print(
          'WARNING: Please specify "output_file_name". Using fallback file name for now.');
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
