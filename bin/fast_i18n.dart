import 'dart:io';

import 'package:fast_i18n/src/builder/build_config_builder.dart';
import 'package:fast_i18n/src/builder/i18n_config_builder.dart';
import 'package:fast_i18n/src/generator/generate.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/parser/parser_facade.dart';
import 'package:fast_i18n/src/parser/yaml_parser.dart';
import 'package:fast_i18n/src/utils.dart';

/// To run this:
/// -> flutter pub run fast_i18n
///
/// Scans translation files and builds the dart file.
/// This is usually faster than the build_runner implementation.
void main(List<String> arguments) async {
  print('Generating translations...\n');

  final watchMode = arguments.length == 1 && arguments[0] == 'watch';
  final stopwatch = Stopwatch();
  if (!watchMode) {
    // only run stopwatch if generating once
    stopwatch.start();
  }

  // get all files recursively (no directories)
  Iterable<FileSystemEntity> files =
      (await Directory.current.list(recursive: true).toList())
          .where((item) => FileSystemEntity.isFileSync(item.path));

  final buildConfig = await getBuildConfig(files);

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
      verbose: true,
      stopwatch: stopwatch,
    );
  }
}

Future<BuildConfig> getBuildConfig(Iterable<FileSystemEntity> files) async {
  BuildConfig? buildConfig;
  for (final file in files) {
    final fileName = file.path.getFileName();

    if (fileName == 'build.yaml') {
      final content = await File(file.path).readAsString();
      buildConfig = YamlParser.parseBuildYaml(content);
      if (buildConfig != null) {
        print('Found build.yaml in ${file.path}');
        break;
      }
    }
  }

  if (buildConfig == null) {
    buildConfig = BuildConfigBuilder.fromMap({});
    print('No build.yaml, use default settings.');
  }

  // convert to absolute paths
  buildConfig = buildConfig.withAbsolutePaths();

  // show build config
  print('');
  print(' -> fileType: ${buildConfig.fileType.getEnumName()}');
  print(' -> baseLocale: ${buildConfig.baseLocale.languageTag}');
  print(' -> fallbackStrategy: ${buildConfig.fallbackStrategy.getEnumName()}');
  print(
      ' -> inputDirectory: ${buildConfig.inputDirectory != null ? buildConfig.inputDirectory : 'null (everywhere)'}');
  print(' -> inputFilePattern: ${buildConfig.inputFilePattern}');
  print(
      ' -> outputDirectory: ${buildConfig.outputDirectory != null ? buildConfig.outputDirectory : 'null (directory of input)'}');
  print(' -> outputFilePattern: ${buildConfig.outputFilePattern}');
  print(' -> translateVar: ${buildConfig.translateVar}');
  print(' -> enumName: ${buildConfig.enumName}');
  print(
      ' -> translationClassVisibility: ${buildConfig.translationClassVisibility.getEnumName()}');
  print(
      ' -> keyCase: ${buildConfig.keyCase != null ? buildConfig.keyCase?.getEnumName() : 'null (no change)'}');
  print(
      ' -> keyCase (for maps): ${buildConfig.keyMapCase != null ? buildConfig.keyMapCase?.getEnumName() : 'null (no change)'}');
  print(
      ' -> paramCase: ${buildConfig.paramCase != null ? buildConfig.paramCase?.getEnumName() : 'null (no change)'}');
  print(
      ' -> stringInterpolation: ${buildConfig.stringInterpolation.getEnumName()}');
  print(' -> renderFlatMap: ${buildConfig.renderFlatMap}');
  print(' -> maps: ${buildConfig.maps}');
  print(' -> pluralization/auto: ${buildConfig.pluralAuto.getEnumName()}');
  print(' -> pluralization/cardinal: ${buildConfig.pluralCardinal}');
  print(' -> pluralization/ordinal: ${buildConfig.pluralOrdinal}');
  print(
      ' -> contexts: ${buildConfig.contexts.isEmpty ? 'no custom contexts' : ''}');
  for (final contextType in buildConfig.contexts) {
    print(
        '    - ${contextType.enumName} { ${contextType.enumValues.join(', ')} }');
  }
  print('');

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

Future<void> generateTranslations({
  required BuildConfig buildConfig,
  required Iterable<FileSystemEntity> files,
  required bool verbose,
  Stopwatch? stopwatch,
}) async {
  // find base name
  String? baseName;
  for (final file in files) {
    final fileName = file.path.getFileName();

    final fileNameNoExtension =
        fileName.replaceAll(buildConfig.inputFilePattern, '');
    final baseFile = Utils.baseFileRegex.firstMatch(fileNameNoExtension);
    if (baseFile != null) {
      baseName = fileNameNoExtension;

      if (verbose) {
        print(
            'Found base name: "$baseName" (used for output file name and class names)');
      }
      break;
    }
  }

  if (baseName == null) {
    print('Error: No base translation file.');
    return;
  }

  // scan translations
  if (verbose) {
    print('Scanning translations...');
    print('');
  }

  final translationList = <I18nData>[];
  String? resultPath;
  for (final file in files) {
    final fileName = file.path.getFileName();
    final fileNameNoExtension =
        fileName.replaceAll(buildConfig.inputFilePattern, '');
    final baseFile = Utils.baseFileRegex.firstMatch(fileNameNoExtension);
    if (baseFile != null) {
      // base file
      final content = await File(file.path).readAsString();
      final currTranslations = ParserFacade.parseTranslations(
        config: buildConfig,
        locale: buildConfig.baseLocale,
        content: content,
      );
      translationList.add(currTranslations);
      resultPath =
          file.path.replaceAll("${Platform.pathSeparator}$fileName", '') +
              Platform.pathSeparator +
              baseName +
              buildConfig.outputFilePattern;

      if (verbose) {
        print(
            '${('(base) ' + buildConfig.baseLocale.languageTag).padLeft(12)} -> ${file.path}');
      }
    } else {
      // secondary files (strings_x)
      final match = Utils.fileWithLocaleRegex.firstMatch(fileNameNoExtension);
      if (match != null) {
        final language = match.group(3);
        final script = match.group(5);
        final country = match.group(7);
        final locale = I18nLocale(
          language: language,
          script: script,
          country: country,
        );
        final content = await File(file.path).readAsString();
        final currTranslations = ParserFacade.parseTranslations(
          config: buildConfig,
          locale: locale,
          content: content,
        );
        translationList.add(currTranslations);

        if (verbose) {
          print('${locale.languageTag.padLeft(12)} -> ${file.path}');
        }
      }
    }
  }

  if (buildConfig.outputDirectory != null) {
    // output directory specified, use this path instead
    resultPath = buildConfig.outputDirectory! +
        Platform.pathSeparator +
        baseName +
        buildConfig.outputFilePattern;
  }

  if (resultPath == null) {
    print('No base file found.');
    return;
  }

  // base locale, then all other locales
  translationList.sort(I18nData.generationComparator);

  // build config
  final config = I18nConfigBuilder.build(
    baseName: baseName,
    buildConfig: buildConfig,
    translationList: translationList,
  );

  // generate
  final String output = generate(
    config: config,
    translations: translationList,
  );

  // write output
  await File(resultPath).writeAsString(output);

  if (verbose) {
    if (config.hasPlurals()) {
      // show pluralization hints if pluralization is configured
      print('');
      print('Pluralization:');
      print(
          ' -> rendered resolvers: ${config.getRenderedPluralResolvers().toList()}');
      print(
          ' -> you must implement these resolvers: ${config.unsupportedPluralLanguages.toList()}');
    }

    print('');
    print('Output: $resultPath');

    if (stopwatch != null)
      print('Translations generated successfully. (${stopwatch.elapsed})');
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
    return this.split(Platform.pathSeparator).last;
  }
}

extension on Object {
  /// expects an enum and get its string representation without enum class name
  String getEnumName() {
    return this.toString().split('.').last;
  }
}
