import 'package:slang/builder/builder/raw_config_builder.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/translation_map.dart';
import 'package:slang/src/builder/decoder/json_decoder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

void main() {
  late String input;
  late String buildYaml;
  late String expectedOutput;

  setUp(() {
    input = loadResource('main/json_simple.json');
    buildYaml = loadResource('main/build_config.yaml');
    expectedOutput = loadResource('main/_expected_no_locale_handling.output');
  });

  test('no locale handling', () {
    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!.copyWith(
        localeHandling: false,
        translationClassVisibility: TranslationClassVisibility.public,
      ),
      baseName: 'translations',
      translationMap: TranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: JsonDecoder().decode(input),
        ),
      inputDirectoryHint: 'fake/path/integration',
    );

    expect(result.joinAsSingleOutput(), expectedOutput);
  });
}
