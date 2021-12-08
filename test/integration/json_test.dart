import 'package:fast_i18n/src/builder/build_config_builder.dart';
import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:fast_i18n/src/generator/generator_facade.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/namespace_translation_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/assets_utils.dart';
import '../util/datetime_utils.dart';

void main() {
  late String jsonEnContent;
  late String jsonDeContent;
  late String expectedOutput;
  late String buildConfigContent;

  setUp(() {
    jsonEnContent = loadAsset('json_en.json');
    jsonDeContent = loadAsset('json_de.json');
    expectedOutput = loadAsset('expected.output');
    buildConfigContent = loadAsset('build_config.yaml');
  });

  test('json', () {
    final parsedEn = TranslationMapBuilder.fromString(
      FileType.json,
      jsonEnContent,
    );

    final parsedDe = TranslationMapBuilder.fromString(
      FileType.json,
      jsonDeContent,
    );

    final buildConfig = BuildConfigBuilder.fromYaml(buildConfigContent)!;

    final result = GeneratorFacade.generate(
      buildConfig: buildConfig,
      baseName: 'translations',
      translationMap: NamespaceTranslationMap()
        ..add(
          locale: I18nLocale.fromString('en'),
          namespace: '',
          translations: parsedEn,
        )
        ..add(
          locale: I18nLocale.fromString('de'),
          namespace: '',
          translations: parsedDe,
        ),
      showPluralHint: false,
      now: birthDate,
    );

    expect(result, expectedOutput);
  });
}
