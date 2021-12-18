import 'package:fast_i18n/src/builder/build_config_builder.dart';
import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:fast_i18n/src/generator_facade.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/namespace_translation_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/resources_utils.dart';

void main() {
  late String compactInput;
  late String buildYaml;
  late String expectedOutput;

  setUp(() {
    compactInput = loadResource('csv_compact.csv');
    buildYaml = loadResource('build_config.yaml');
    expectedOutput = loadResource('expected_single.output');
  });

  test('compact csv', () {
    final parsed = TranslationMapBuilder.fromString(
      FileType.csv,
      compactInput,
    );

    final result = GeneratorFacade.generate(
      buildConfig: BuildConfigBuilder.fromYaml(buildYaml)!,
      baseName: 'translations',
      translationMap: NamespaceTranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: parsed['en'],
        )
        ..addTranslations(
          locale: I18nLocale.fromString('de'),
          translations: parsed['de'],
        ),
      showPluralHint: false,
    );

    expect(result.joinAsSingleOutput(), expectedOutput);
  });
}
