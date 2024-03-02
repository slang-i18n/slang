import 'package:slang/builder/builder/raw_config_builder.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/translation_map.dart';
import 'package:slang/src/builder/decoder/yaml_decoder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

void main() {
  late String enInput;
  late String deInput;
  late String buildYaml;
  late String expectedOutput;

  setUp(() {
    enInput = loadResource('main/yaml_en.yaml');
    deInput = loadResource('main/yaml_de.yaml');
    buildYaml = loadResource('main/build_config.yaml');
    expectedOutput = loadResource('main/_expected_single.output');
  });

  test('yaml', () {
    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!,
      baseName: 'translations',
      translationMap: TranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: YamlDecoder().decode(enInput),
        )
        ..addTranslations(
          locale: I18nLocale.fromString('de'),
          translations: YamlDecoder().decode(deInput),
        ),
      inputDirectoryHint: 'fake/path/integration',
    );

    expect(result.joinAsSingleOutput(), expectedOutput);
  });
}
