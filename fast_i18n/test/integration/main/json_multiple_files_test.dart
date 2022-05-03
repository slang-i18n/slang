import 'package:fast_i18n/builder/builder/build_config_builder.dart';
import 'package:fast_i18n/builder/decoder/json_decoder.dart';
import 'package:fast_i18n/builder/generator_facade.dart';
import 'package:fast_i18n/builder/model/build_config.dart';
import 'package:fast_i18n/builder/model/i18n_locale.dart';
import 'package:fast_i18n/builder/model/namespace_translation_map.dart';
import 'package:test/test.dart';

import '../../util/build_config_utils.dart';
import '../../util/resources_utils.dart';

void main() {
  late String enInput;
  late String deInput;
  late String buildYaml;
  late String expectedMainOutput;
  late String expectedEnOutput;
  late String expectedDeOutput;
  late String expectedFlatMapOutput;

  setUp(() {
    enInput = loadResource('main/json_en.json');
    deInput = loadResource('main/json_de.json');
    buildYaml = loadResource('main/build_config.yaml');
    expectedMainOutput = loadResource('main/expected_main.output');
    expectedEnOutput = loadResource('main/expected_en.output');
    expectedDeOutput = loadResource('main/expected_de.output');
    expectedFlatMapOutput = loadResource('main/expected_map.output');
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
          translations: JsonDecoder().decode(enInput),
        )
        ..addTranslations(
          locale: I18nLocale.fromString('de'),
          translations: JsonDecoder().decode(deInput),
        ),
      showPluralHint: false,
    );

    expect(result.header, expectedMainOutput);
    expect(result.translations[I18nLocale.fromString('en')], expectedEnOutput);
    expect(result.translations[I18nLocale.fromString('de')], expectedDeOutput);
    expect(result.flatMap, expectedFlatMapOutput);
  });
}
