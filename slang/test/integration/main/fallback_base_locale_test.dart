import 'package:slang/src/builder/builder/raw_config_builder.dart';
import 'package:slang/src/builder/decoder/csv_decoder.dart';
import 'package:slang/src/builder/decoder/json_decoder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

void main() {
  late String compactInput;
  late String buildYaml;
  late String expectedMainOutput;
  late String expectedEnOutput;
  late String expectedDeOutput;

  late String specialEnInput;
  late String specialDeInput;
  late String specialExpectedMainOutput;
  late String specialExpectedEnOutput;
  late String specialExpectedDeOutput;

  setUp(() {
    compactInput = loadResource('main/csv_compact.csv');
    buildYaml = loadResource('main/build_config.yaml');
    expectedMainOutput = loadResource(
      'main/_expected_fallback_base_locale_main.output',
    );
    expectedEnOutput = loadResource(
      'main/_expected_fallback_base_locale_en.output',
    );
    expectedDeOutput = loadResource(
      'main/_expected_fallback_base_locale_de.output',
    );

    specialEnInput = loadResource('main/fallback_en.json');
    specialDeInput = loadResource('main/fallback_de.json');
    specialExpectedMainOutput = loadResource(
      'main/_expected_fallback_base_locale_special_main.output',
    );
    specialExpectedEnOutput = loadResource(
      'main/_expected_fallback_base_locale_special_en.output',
    );
    specialExpectedDeOutput = loadResource(
      'main/_expected_fallback_base_locale_special_de.output',
    );
  });

  test('fallback with generic integration data', () {
    final parsed = CsvDecoder().decode(compactInput);

    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!.copyWith(
        fallbackStrategy: FallbackStrategy.baseLocale,
      ),
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

    expect(result.main, expectedMainOutput);
    expect(result.translations[I18nLocale.fromString('en')], expectedEnOutput);
    expect(result.translations[I18nLocale.fromString('de')], expectedDeOutput);
  });

  test('fallback with special integration data', () {
    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!.copyWith(
        fallbackStrategy: FallbackStrategy.baseLocale,
      ),
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

    expect(result.main, specialExpectedMainOutput);
    expect(
      result.translations[I18nLocale.fromString('en')],
      specialExpectedEnOutput,
    );
    expect(
      result.translations[I18nLocale.fromString('de')],
      specialExpectedDeOutput,
    );
  });
}
