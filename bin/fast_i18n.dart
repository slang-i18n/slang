import 'dart:io';

import 'package:fast_i18n/src/builder/build_config_builder.dart';
import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:fast_i18n/src/generator_facade.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/namespace_translation_map.dart';
import 'package:fast_i18n/src/utils/regex_utils.dart';
import 'package:fast_i18n/src/utils/path_utils.dart';

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
      buildConfig = BuildConfigBuilder.fromYaml(content);
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
  print(' -> outputFilePattern (deprecated): ${buildConfig.outputFilePattern}');
  print(' -> outputFileName: ${buildConfig.outputFileName}');
  print(' -> outputFileFormat: ${buildConfig.outputFormat.getEnumName()}');
  print(' -> namespaces: ${buildConfig.namespaces}');
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
  print(' -> renderTimestamp: ${buildConfig.renderTimestamp}');
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
  print(
      ' -> interfaces: ${buildConfig.interfaces.isEmpty ? 'no interfaces' : ''}');
  for (final interface in buildConfig.interfaces) {
    print('    - ${interface.name}');
    print(
        '        Attributes: ${interface.attributes.isEmpty ? 'no attributes' : ''}');
    for (final a in interface.attributes) {
      print(
          '          - ${a.returnType} ${a.attributeName} (${a.parameters.isEmpty ? 'no parameters' : a.parameters.map((p) => p.parameterName).join(',')})${a.optional ? ' (optional)' : ''}');
    }
    print('        Paths: ${interface.paths.isEmpty ? 'no paths' : ''}');
    for (final path in interface.paths) {
      print(
          '          - ${path.isContainer ? 'children of: ' : ''}${path.path}');
    }
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

const _defaultPadLeft = 12;
const _namespacePadLeft = 24;

/// Reads the translations from hard drive and generates the g.dart file
/// The [files] are already filtered (only translation files!).
Future<void> generateTranslations({
  required BuildConfig buildConfig,
  required Iterable<FileSystemEntity> files,
  required bool verbose,
  Stopwatch? stopwatch,
}) async {
  // STEP 1: determine base name and output file name / path
  String? baseName;
  String? outputFileName;
  final String outputFilePath;

  if (buildConfig.outputFileName != null) {
    // use newer version
    // this will have a default non-null value in the future (6.0.0+)
    outputFileName = buildConfig.outputFileName!;
    baseName = buildConfig.outputFileName!.getFileNameNoExtension();
  } else {
    // use legacy mode by taking the namespace name
    for (final file in files) {
      final fileNameNoExtension = file.path.getFileNameNoExtension();
      final baseFile = RegexUtils.baseFileRegex.firstMatch(fileNameNoExtension);
      if (baseFile != null) {
        baseName = fileNameNoExtension;
        outputFileName = baseName + buildConfig.outputFilePattern;

        if (verbose) {
          print(
              'Found base name: "$baseName" (used for output file name and class names)');
        }
        break;
      }
    }
  }

  if (baseName == null || outputFileName == null) {
    print('Error: No base translation file.');
    return;
  }

  if (buildConfig.outputDirectory != null) {
    // output directory specified, use this path instead
    outputFilePath =
        buildConfig.outputDirectory! + Platform.pathSeparator + outputFileName;
  } else {
    // use the directory of the first (random) translation file
    final fileName = files.first.path.getFileName();
    outputFilePath =
        files.first.path.replaceAll("${Platform.pathSeparator}$fileName", '') +
            Platform.pathSeparator +
            outputFileName;
  }

  // STEP 2: scan translations
  if (verbose) {
    print('Scanning translations...');
    print('');
  }

  final translationMap = NamespaceTranslationMap();
  final padLeft = buildConfig.namespaces ? _namespacePadLeft : _defaultPadLeft;
  for (final file in files) {
    final content = await File(file.path).readAsString();
    final fileNameNoExtension = file.path.getFileNameNoExtension();
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

          if (verbose) {
            final namespaceLog = buildConfig.namespaces ? '($namespace) ' : '';
            final base = locale == buildConfig.baseLocale ? '(base) ' : '';
            print(
                '${('$base$namespaceLog${locale.languageTag}').padLeft(padLeft)} -> ${file.path}');
          }
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

        if (verbose) {
          final namespaceLog = buildConfig.namespaces ? '($namespace) ' : '';
          print(
              '${('(base) $namespaceLog${buildConfig.baseLocale.languageTag}').padLeft(padLeft)} -> ${file.path}');
        }
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

        if (verbose) {
          final namespaceLog = buildConfig.namespaces ? '($namespace) ' : '';
          print(
              '${(namespaceLog + locale.languageTag).padLeft(padLeft)} -> ${file.path}');
        }
      }
    }
  }

  // STEP 3: generate .g.dart content
  final result = GeneratorFacade.generate(
    buildConfig: buildConfig,
    baseName: baseName,
    translationMap: translationMap,
    showPluralHint: verbose,
  );

  // STEP 4: write output to hard drive
  if (buildConfig.outputFormat == OutputFormat.singleFile) {
    // single file
    File(outputFilePath).writeAsStringSync(result.joinAsSingleOutput());
  } else {
    // multiple files
    File(BuildResultPaths.mainPath(outputFilePath))
        .writeAsStringSync(result.header);
    for (final entry in result.translations.entries) {
      final locale = entry.key;
      final localeTranslations = entry.value;
      File(BuildResultPaths.localePath(
        outputPath: outputFilePath,
        locale: locale,
        pathSeparator: Platform.pathSeparator,
      )).writeAsStringSync(localeTranslations);
    }
    if (result.flatMap != null) {
      File(BuildResultPaths.flatMapPath(
        outputPath: outputFilePath,
        pathSeparator: Platform.pathSeparator,
      )).writeAsStringSync(result.flatMap!);
    }
  }

  if (verbose) {
    if (buildConfig.outputFileName == null && buildConfig.namespaces) {
      print('');
      print(
          'WARNING: Please specify "output_file_name". Using fallback file name for now.');
    }

    print('');
    print('Output: $outputFilePath');

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
    return PathUtils.getFileName(this);
  }

  /// converts /some/path/file.json to file
  String getFileNameNoExtension() {
    return PathUtils.getFileNameNoExtension(this);
  }
}

extension on Object {
  /// expects an enum and get its string representation without enum class name
  String getEnumName() {
    return this.toString().split('.').last;
  }
}
