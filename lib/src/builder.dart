import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:fast_i18n/src/generator/generate.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/pluralization_resolvers.dart';
import 'package:fast_i18n/src/parser_json.dart';
import 'package:fast_i18n/src/utils.dart';
import 'package:glob/glob.dart';

Builder i18nBuilder(BuilderOptions options) => I18nBuilder(options);

class I18nBuilder implements Builder {
  I18nBuilder(this.options);

  final BuilderOptions options;

  bool _generated = false;

  String get inputFilePattern =>
      options.config['input_file_pattern'] ??
      BuildConfig.defaultInputFilePattern;
  String get outputFilePattern =>
      options.config['output_file_pattern'] ??
      BuildConfig.defaultOutputFilePattern;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final buildConfig = BuildConfig(
        nullSafety:
            options.config['null_safety'] ?? BuildConfig.defaultNullSafety,
        baseLocale: I18nLocale.fromString(
            options.config['base_locale'] ?? BuildConfig.defaultBaseLocale),
        fallbackStrategy:
            (options.config['fallback_strategy'] as String?)?.toFallbackStrategy() ??
                BuildConfig.defaultFallbackStrategy,
        inputDirectory: options.config['input_directory'] ??
            BuildConfig.defaultInputDirectory,
        inputFilePattern: inputFilePattern,
        outputDirectory: options.config['output_directory'] ??
            BuildConfig.defaultOutputDirectory,
        outputFilePattern: outputFilePattern,
        translateVar:
            options.config['translate_var'] ?? BuildConfig.defaultTranslateVar,
        enumName: options.config['enum_name'] ?? BuildConfig.defaultEnumName,
        translationClassVisibility:
            (options.config['translation_class_visibility'] as String?)
                    ?.toTranslationClassVisibility() ??
                BuildConfig.defaultTranslationClassVisibility,
        keyCase: (options.config['key_case'] as String?)?.toKeyCase() ??
            BuildConfig.defaultKeyCase,
        stringInterpolation: (options.config['string_interpolation'] as String?)
                ?.toStringInterpolation() ??
            BuildConfig.defaultStringInterpolation,
        renderFlatMap:
            options.config['flat_map'] ?? BuildConfig.defaultRenderFlatMap,
        maps: options.config['maps']?.cast<String>() ?? BuildConfig.defaultMaps,
        pluralCardinal: options.config['pluralization']?['cardinal']?.cast<String>() ??
            BuildConfig.defaultCardinal,
        pluralOrdinal: options.config['pluralization']?['ordinal']?.cast<String>() ?? BuildConfig.defaultOrdinal);

    if (buildConfig.inputDirectory != null &&
        !buildStep.inputId.path.contains(buildConfig.inputDirectory!)) return;

    // only generate once
    if (_generated) return;

    _generated = true;

    // detect all locales, their assetId and the baseName
    final Map<AssetId, I18nLocale> assetMap = Map();
    String? baseName;

    final Glob findAssetsPattern = buildConfig.inputDirectory != null
        ? Glob('**${buildConfig.inputDirectory}/*$inputFilePattern')
        : Glob('**$inputFilePattern');

    await buildStep.findAssets(findAssetsPattern).forEach((assetId) {
      final fileNameNoExtension =
          assetId.pathSegments.last.replaceAll(inputFilePattern, '');

      final baseFile = Utils.baseFileRegex.firstMatch(fileNameNoExtension);
      if (baseFile != null) {
        // base file
        assetMap[assetId] = buildConfig.baseLocale;
        baseName = fileNameNoExtension;
      } else {
        // secondary files (strings_x)
        final match = Utils.fileWithLocaleRegex.firstMatch(fileNameNoExtension);
        if (match != null) {
          final language = match.group(3);
          final script = match.group(5);
          final country = match.group(7);
          assetMap[assetId] = I18nLocale(
              language: language ?? '', script: script, country: country);
        }
      }
    });

    if (baseName == null) {
      print('Error: No base translation file.');
      return;
    }

    // map each assetId to I18nData
    final localesWithData = Map<AssetId, I18nData>();

    for (MapEntry<AssetId, I18nLocale> asset in assetMap.entries) {
      I18nLocale locale = asset.value;
      String content = await buildStep.readAsString(asset.key);
      I18nData representation = parseJSON(buildConfig, locale, content);
      localesWithData[asset.key] = representation;
    }

    // generate
    final String output = generate(
        config: I18nConfig(
          nullSafety: buildConfig.nullSafety,
          baseName: baseName!,
          baseLocale: buildConfig.baseLocale,
          fallbackStrategy: buildConfig.fallbackStrategy,
          renderedPluralizationResolvers: buildConfig
                      .pluralCardinal.isNotEmpty ||
                  buildConfig.pluralOrdinal.isNotEmpty
              ? PLURALIZATION_RESOLVERS
                  .where((resolver) => assetMap.values
                      .any((locale) => locale.language == resolver.language))
                  .toList()
              : [],
          keyCase: buildConfig.keyCase,
          translateVariable: buildConfig.translateVar,
          enumName: buildConfig.enumName,
          translationClassVisibility: buildConfig.translationClassVisibility,
          renderFlatMap: buildConfig.renderFlatMap,
        ),
        translations: localesWithData.values.toList()
          ..sort(I18nData
              .generationComparator)); // base locale, then all other locales

    // write only to main locale
    final AssetId baseId =
        localesWithData.entries.firstWhere((element) => element.value.base).key;

    final finalOutputDirectory = buildConfig.outputDirectory ??
        (baseId.pathSegments..removeLast()).join('/');
    final String outFilePath =
        '$finalOutputDirectory/$baseName$outputFilePattern';

    File(outFilePath).writeAsStringSync(output);
  }

  @override
  get buildExtensions => {
        inputFilePattern: [outputFilePattern],
      };
}
