import 'dart:async';
import 'package:build/build.dart';
import 'package:fast_i18n/src/generator.dart';
import 'package:fast_i18n/src/model.dart';
import 'package:fast_i18n/src/parser_json.dart';
import 'package:fast_i18n/utils.dart';
import 'package:glob/glob.dart';

Builder i18nBuilder(BuilderOptions options) => I18nBuilder();

class I18nBuilder implements Builder {
  bool _generated = false;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    if (buildStep.inputId.pathSegments.last == 'config.i18n.json' ||
        buildStep.inputId.pathSegments.last.indexOf('_') != -1) return;

    // only generate once
    if (!_generated) {
      _generated = true;

      // detect all locales, their assetId and the baseName
      Map<AssetId, String> locales = Map();
      String baseName;
      AssetId configAsset;
      await buildStep.findAssets(Glob('**.i18n.json')).forEach((assetId) {
        String fileNameNoExtension =
            assetId.pathSegments.last.replaceAll('.i18n.json', '');

        if (fileNameNoExtension == 'config') {
          configAsset = assetId;
        } else {
          RegExpMatch match = Utils.localeRegex.firstMatch(fileNameNoExtension);
          if (match != null) {
            String language = match.group(1);
            String country = match.group(3);

            if (country != null)
              locales[assetId] = language + '-' + country.toLowerCase();
            else
              locales[assetId] = language;
          } else {
            locales[assetId] = '';
            baseName = fileNameNoExtension;
          }
        }
      });

      I18nConfig config;
      if (configAsset != null) {
        String content = await buildStep.readAsString(configAsset);
        config = parseConfig(content);
      } else {
        // default config
        config = I18nConfig('', []);
      }

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
      String output = generate(localesWithData.values.toList()
        ..sort((a, b) => a.locale.compareTo(b.locale)));

      // write only to main locale
      AssetId baseId = localesWithData.entries
          .firstWhere((element) => element.value.base)
          .key;
      AssetId newId = AssetId(
          baseId.package, baseId.path.replaceAll('.i18n.json', '.g.dart'));
      await buildStep.writeAsString(newId, output);
    }
  }

  @override
  final buildExtensions = const {
    '.i18n.json': ['.g.dart']
  };
}
