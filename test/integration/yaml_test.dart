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
  late String yamlEnContent;
  late String yamlDeContent;
  late String expectedOutput;
  late String buildConfigContent;

  setUp(() {
    yamlEnContent = loadAsset('yaml_en.yaml');
    yamlDeContent = loadAsset('yaml_de.yaml');
    expectedOutput = loadAsset('expected.output');
    buildConfigContent = loadAsset('build_config.yaml');
  });

  test('yaml', () {
    final parsedEn = TranslationMapBuilder.fromString(
      FileType.yaml,
      yamlEnContent,
    );

    final parsedDe = TranslationMapBuilder.fromString(
      FileType.yaml,
      yamlDeContent,
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
