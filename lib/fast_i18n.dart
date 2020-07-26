library fast_i18n;

import 'dart:async';
import 'package:build/build.dart';
import 'package:fast_i18n/src/generator.dart';
import 'package:fast_i18n/src/model.dart';
import 'package:fast_i18n/src/parser_json.dart';
import 'package:glob/glob.dart';

Builder i18nBuilder(BuilderOptions options) => I18nBuilder();

class I18nBuilder implements Builder {
  bool _analyzed = false;
  Map<AssetId, String> _locales = Map();
  String _baseName;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    if (!_analyzed) {
      // initialize _locales and _baseName
      await buildStep.findAssets(Glob('**.i18n.json')).forEach((assetId) {
        String fileNameNoExtension =
            assetId.pathSegments.last.replaceAll('.i18n.json', '');
        if (fileNameNoExtension.contains('_')) {
          _locales[assetId] = fileNameNoExtension.split('_').last;
        } else {
          _locales[assetId] = '';
          _baseName = fileNameNoExtension;
        }
      });

      _analyzed = true;
    }

    AssetId inputId = buildStep.inputId;
    String content = await buildStep.readAsString(inputId);
    I18nData representation = parseJSON(_baseName, _locales[inputId], content);
    String output = generate(representation, _locales.values.toList());
    AssetId newId = AssetId(
        inputId.package, inputId.path.replaceAll('.i18n.json', '.g.dart'));
    await buildStep.writeAsString(newId, output);
  }

  @override
  final buildExtensions = const {
    '.i18n.json': ['.g.dart']
  };
}
