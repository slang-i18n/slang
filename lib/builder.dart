import 'dart:async';
import 'dart:io';

// ignore: import_of_legacy_library_into_null_safe
import 'package:build/build.dart';
import 'package:fast_i18n/src/generator.dart';
import 'package:fast_i18n/src/model.dart';
import 'package:fast_i18n/src/parser_json.dart';
import 'package:fast_i18n/utils.dart';
import 'package:glob/glob.dart';

Builder i18nBuilder(BuilderOptions options) => I18nBuilder(options);

class I18nBuilder implements Builder {
  I18nBuilder(this.options);

  static const String defaultBaseLocale = 'en';
  static const String defaultBaseName = 'strings';
  static const String defaultTranslateVar = 't';
  static const String defaultEnumName = 'AppLocale';
  static const String defaultInputFilePattern = '.i18n.json';
  static const String defaultOutputFilePattern = '.g.dart';

  final BuilderOptions options;

  bool _generated = false;

  String get inputFilePattern =>
      options.config['input_file_pattern'] ?? defaultInputFilePattern;
  String get outputFilePattern =>
      options.config['output_file_pattern'] ?? defaultOutputFilePattern;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final String baseLocale =
        Utils.normalize(options.config['base_locale'] ?? defaultBaseLocale);
    final String? inputDirectory = options.config['input_directory'];
    final String? outputDirectory = options.config['output_directory'];
    final String translateVar =
        options.config['output_translate_var'] ?? defaultTranslateVar;
    final String enumName =
        options.config['output_enum_name'] ?? defaultEnumName;
    final String? keyCase = options.config['key_case'];
    final List<String> maps = options.config['maps']?.cast<String>() ?? [];

    if (inputDirectory != null &&
        !buildStep.inputId.path.contains(inputDirectory)) return;

    // only generate once
    if (_generated) return;

    _generated = true;

    // detect all locales, their assetId and the baseName
    final Map<AssetId, String> locales = Map();
    String? baseName;

    final Glob findAssetsPattern = inputDirectory != null
        ? Glob('**$inputDirectory/*$inputFilePattern')
        : Glob('**$inputFilePattern');

    await buildStep.findAssets(findAssetsPattern).forEach((assetId) {
      final fileNameNoExtension =
          assetId.pathSegments.last.replaceAll(inputFilePattern, '');
      final match = Utils.localeRegex.firstMatch(fileNameNoExtension);

      if (match != null) {
        if (match.group(2) != null) {
          baseName = match.group(2);
        }

        final language = match.group(3);
        final country = match.group(5);

        if (country != null) {
          locales[assetId] = '$language-$country';
        } else if (language != null) {
          locales[assetId] = language;
        }
      } else {
        locales[assetId] = baseLocale;
        baseName = fileNameNoExtension;
      }
    });

    if (baseName == null) baseName = defaultBaseName;

    // build config which applies to all locales
    final config = I18nConfig(
        baseName: baseName!,
        baseLocale: baseLocale,
        maps: maps,
        keyCase: keyCase,
        translateVariable: translateVar,
        enumName: enumName);

    // map each assetId to I18nData
    final localesWithData = Map<AssetId, I18nData>();

    for (MapEntry<AssetId, String> asset in locales.entries) {
      String locale = asset.value;
      String content = await buildStep.readAsString(asset.key);
      I18nData representation = parseJSON(config, baseName!, locale, content);
      localesWithData[asset.key] = representation;
    }

    // generate
    final String output = generate(
        config: config,
        translations: localesWithData.values.toList()
          ..sort((a, b) => a.locale.compareTo(b.locale)));

    // write only to main locale
    final AssetId baseId =
        localesWithData.entries.firstWhere((element) => element.value.base).key;

    final finalOutputDirectory =
        outputDirectory ?? (baseId.pathSegments..removeLast()).join('/');
    final String outFilePath =
        '$finalOutputDirectory/$baseName$outputFilePattern';

    File(outFilePath).writeAsStringSync(output);
  }

  @override
  get buildExtensions => {
        inputFilePattern: [outputFilePattern],
      };
}
