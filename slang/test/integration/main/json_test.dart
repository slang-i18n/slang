import 'package:slang/src/builder/builder/raw_config_builder.dart';
import 'package:slang/src/builder/decoder/json_decoder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

void main() {
  late String enInput;
  late String deInput;
  late String buildYaml;
  late String expectedMainOutput;
  late String expectedEnOutput;
  late String expectedDeOutput;

  setUp(() {
    enInput = loadResource('main/json_en.json');
    deInput = loadResource('main/json_de.json');
    buildYaml = loadResource('main/build_config.yaml');
    expectedMainOutput = loadResource('main/_expected_main.output');
    expectedEnOutput = loadResource('main/_expected_en.output');
    expectedDeOutput = loadResource('main/_expected_de.output');
  });

  test('json', () {
    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!,
      translationMap: TranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: JsonDecoder().decode(enInput),
        )
        ..addTranslations(
          locale: I18nLocale.fromString('de'),
          translations: JsonDecoder().decode(deInput),
        ),
      inputDirectoryHint: 'fake/path/integration',
    );

    expect(result.main, expectedMainOutput);
    expect(result.translations[I18nLocale.fromString('en')], expectedEnOutput);
    expect(result.translations[I18nLocale.fromString('de')], expectedDeOutput);
  });
}
