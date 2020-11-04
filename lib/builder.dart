import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:fast_i18n/src/generator.dart';
import 'package:fast_i18n/src/model.dart';
import 'package:fast_i18n/src/parser_json.dart';
import 'package:fast_i18n/utils.dart';
import 'package:glob/glob.dart';

Builder i18nBuilder(BuilderOptions options) => I18nBuilder(options);

class I18nBuilder implements Builder {
  I18nBuilder(this.options);

  static const String defaultInputFilePattern = '.i18n.json';
  static const String defaultOutputFilePattern = '.g.dart';

  final BuilderOptions options;

  bool _generated = false;

  String get inputFilePattern => options.config['input_file_pattern'] ?? defaultInputFilePattern;
  String get outputFilePattern => options.config['output_file_pattern'] ?? defaultOutputFilePattern;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    String baseLocale = options.config['base_locale'] ?? 'en';
    String inputDirectory = options.config['input_directory'];
    String outputDirectory = options.config['output_directory'];
    String keyCase = options.config['key_case'];
    List<String> maps = options.config['maps']?.cast<String>() ?? [];

    I18nConfig config = I18nConfig(baseLocale, maps);

    if (null != inputDirectory && !buildStep.inputId.path.contains(inputDirectory)) {
      return;
    }

    // only generate once
    if (!_generated) {
      _generated = true;

      // detect all locales, their assetId and the baseName
      Map<AssetId, String> locales = Map();
      String baseName = 'strings';

      final Glob findAssetsPattern = null != inputDirectory
          ? Glob('**$inputDirectory/*$inputFilePattern')
          : Glob('**$inputFilePattern');

      await buildStep.findAssets(findAssetsPattern).forEach((assetId) {
        String fileNameNoExtension = assetId.pathSegments.last.replaceAll(inputFilePattern, '');

        RegExpMatch match = Utils.localeRegex.firstMatch(fileNameNoExtension);

        if (match != null) {
          if (null != match.group(2)) {
            baseName = match.group(2);
          }

          String language = match.group(3);
          String country = match.group(5);

          if (country != null) {
            locales[assetId] = language + '-' + country.toLowerCase();
          } else {
            locales[assetId] = language;
          }
        } else {
          locales[assetId] = '';
          baseName = fileNameNoExtension;
        }
      });

      // map each assetId to I18nData
      Map<AssetId, I18nData> localesWithData = Map();

      for (AssetId assetId in locales.keys) {
        String locale = locales[assetId];
        if (locale == '') locale = config.baseLocale;

        String content = await buildStep.readAsString(assetId);
        I18nData representation = parseJSON(config, baseName, locale, content);
        localesWithData[assetId] = representation;
      }

      // generate
      String output = generate(
        localesWithData.values.toList()
          ..sort((a, b) => a.locale.compareTo(b.locale)),
        keyCase,
      );

      // write only to main locale
      AssetId baseId = localesWithData.entries
          .firstWhere((element) => element.value.base)
          .key;

      if (null == outputDirectory) {
        outputDirectory = (baseId.pathSegments..removeLast()).join('/');
      }

      final String outFilePath = '$outputDirectory/$baseName$outputFilePattern';

      File(outFilePath).writeAsStringSync(output);
    }
  }

  @override
  get buildExtensions => {
    inputFilePattern: [outputFilePattern],
  };
}
