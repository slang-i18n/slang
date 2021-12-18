import 'package:fast_i18n/src/builder/build_config_builder.dart';
import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:fast_i18n/src/generator_facade.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/namespace_translation_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/build_config_utils.dart';
import '../util/resources_utils.dart';

void main() {
  late String enInput;
  late String deInput;
  late String buildYaml;
  late String expectedMainOutput;
  late String expectedEnOutput;
  late String expectedDeOutput;
  late String expectedFlatMapOutput;

  setUp(() {
    enInput = loadResource('json_en.json');
    deInput = loadResource('json_de.json');
    buildYaml = loadResource('build_config.yaml');
    expectedMainOutput = loadResource('expected_main.output');
    expectedEnOutput = loadResource('expected_en.output');
    expectedDeOutput = loadResource('expected_de.output');
    expectedFlatMapOutput = loadResource('expected_map.output');
  });

  test('json', () {
    final result = GeneratorFacade.generate(
      buildConfig: BuildConfigBuilder.fromYaml(buildYaml)!.copyWith(
        outputFormat: OutputFormat.multipleFiles,
      ),
      baseName: 'translations',
      translationMap: NamespaceTranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: TranslationMapBuilder.fromString(
            FileType.json,
            enInput,
          ),
        )
        ..addTranslations(
          locale: I18nLocale.fromString('de'),
          translations: TranslationMapBuilder.fromString(
            FileType.json,
            deInput,
          ),
        ),
      showPluralHint: false,
    );

    expect(result.header, expectedMainOutput);
    expect(result.translations[I18nLocale.fromString('en')], expectedEnOutput);
    expect(result.translations[I18nLocale.fromString('de')], expectedDeOutput);
    expect(result.flatMap, expectedFlatMapOutput);
  });
}
