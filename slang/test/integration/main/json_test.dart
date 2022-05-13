import 'package:slang/builder/builder/build_config_builder.dart';
import 'package:slang/builder/decoder/json_decoder.dart';
import 'package:slang/builder/generator_facade.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/namespace_translation_map.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

void main() {
  late String enInput;
  late String deInput;
  late String buildYaml;
  late String expectedOutput;

  setUp(() {
    enInput = loadResource('main/json_en.json');
    deInput = loadResource('main/json_de.json');
    buildYaml = loadResource('main/build_config.yaml');
    expectedOutput = loadResource('main/expected_single.output');
  });

  test('json', () {
    final result = GeneratorFacade.generate(
      buildConfig: BuildConfigBuilder.fromYaml(buildYaml)!,
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
    );

    expect(result.joinAsSingleOutput(), expectedOutput);
  });
}
