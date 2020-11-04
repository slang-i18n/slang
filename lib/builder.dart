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

  static const String defaultFilePattern = '.i18n.json';

  final BuilderOptions options;

  bool _generated = false;

  String get filesPattern => options.config['files_pattern'] ?? defaultFilePattern;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    String directoryInPath = options.config['directory_in'];
    String baseLocale = options.config['base_locale'];
    List<String> maps = options.config['maps']?.cast<String>();
    String directoryOutPath = options.config['directory_out'];
    String keyCase = options.config['key_case'];

    I18nConfig config = I18nConfig(baseLocale ?? '', maps ?? []);

    if (null != directoryInPath && !buildStep.inputId.path.contains(directoryInPath)) {
      return;
    }

    // only generate once
    if (!_generated) {
      _generated = true;

      // detect all locales, their assetId and the baseName
      Map<AssetId, String> locales = Map();
      String baseName = 'strings';

      final Glob findAssetsPattern = null != directoryInPath
          ? Glob('**$directoryInPath/*$filesPattern')
          : Glob('**$filesPattern');

      await buildStep.findAssets(findAssetsPattern).forEach((assetId) {
        String fileNameNoExtension = assetId.pathSegments.last.replaceAll(filesPattern, '');

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

      if (null == directoryOutPath) {
        directoryOutPath = (baseId.pathSegments..removeLast()).join('/');
      }

      final String outFilePath = '$directoryOutPath/$baseName.g.dart';

      File(outFilePath).writeAsStringSync(output);
    }
  }

  @override
  get buildExtensions => {
    filesPattern: ['.g.dart'],
  };
}
