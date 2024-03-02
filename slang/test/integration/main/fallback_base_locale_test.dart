import 'package:slang/builder/builder/raw_config_builder.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/translation_map.dart';
import 'package:slang/src/builder/decoder/csv_decoder.dart';
import 'package:slang/src/builder/decoder/json_decoder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

void main() {
  late String compactInput;
  late String buildYaml;
  late String expectedOutput;

  late String specialEnInput;
  late String specialDeInput;
  late String specialExpectedOutput;

  setUp(() {
    compactInput = loadResource('main/csv_compact.csv');
    buildYaml = loadResource('main/build_config.yaml');
    expectedOutput = loadResource(
      'main/_expected_fallback_base_locale.output',
    );

    specialEnInput = loadResource('main/fallback_en.json');
    specialDeInput = loadResource('main/fallback_de.json');
    specialExpectedOutput = loadResource(
      'main/_expected_fallback_base_locale_special.output',
    );
  });

  test('fallback with generic integration data', () {
    final parsed = CsvDecoder().decode(compactInput);

    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!.copyWith(
        fallbackStrategy: FallbackStrategy.baseLocale,
      ),
      baseName: 'translations',
      translationMap: TranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: parsed['en'],
        )
        ..addTranslations(
          locale: I18nLocale.fromString('de'),
          translations: parsed['de'],
        ),
      inputDirectoryHint: 'fake/path/integration',
    );

    expect(result.joinAsSingleOutput(), expectedOutput);
  });

  test('fallback with special integration data', () {
    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!.copyWith(
        fallbackStrategy: FallbackStrategy.baseLocale,
      ),
      baseName: 'translations',
      translationMap: TranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: JsonDecoder().decode(specialEnInput),
        )
        ..addTranslations(
          locale: I18nLocale.fromString('de'),
          translations: JsonDecoder().decode(specialDeInput),
        ),
      inputDirectoryHint: 'fake/path/integration',
    );

    expect(result.joinAsSingleOutput(), specialExpectedOutput);
  });
}
