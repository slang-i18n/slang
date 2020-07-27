import 'dart:async';
import 'package:build/build.dart';
import 'package:fast_i18n/src/generator.dart';
import 'package:fast_i18n/src/model.dart';
import 'package:fast_i18n/src/parser_json.dart';
import 'package:glob/glob.dart';

Builder i18nBuilder(BuilderOptions options) => I18nBuilder();

class I18nBuilder implements Builder {
  bool _generated = false;

  @override
  FutureOr<void> build(BuildStep buildStep) async {

    if (buildStep.inputId.pathSegments.last.indexOf('_') != -1)
      return;

    // only generate once
    if (!_generated) {
      _generated = true;

      // detect all locales, their assetId and the baseName
      Map<AssetId, String> locales = Map();
      String baseName;
      await buildStep.findAssets(Glob('**.i18n.json')).forEach((assetId) {
        String fileNameNoExtension =
            assetId.pathSegments.last.replaceAll('.i18n.json', '');
        if (fileNameNoExtension.contains('_')) {
          locales[assetId] = fileNameNoExtension.split('_').last;
        } else {
          locales[assetId] = '';
          baseName = fileNameNoExtension;
        }
      });

      // map each assetId to I18nData
      Map<AssetId, I18nData> localesWithData = Map();
      for (AssetId assetId in locales.keys) {
        String content = await buildStep.readAsString(assetId);
        I18nData representation =
            parseJSON(baseName, locales[assetId], content);
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
