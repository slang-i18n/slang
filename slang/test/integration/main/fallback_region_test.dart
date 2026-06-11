import 'package:slang/src/builder/builder/raw_config_builder.dart';
import 'package:slang/src/builder/decoder/json_decoder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';
import '../../util/setup.dart';

void main() {
  late String enInput;
  late String deInput;
  late String deDeInput;
  late String buildYaml;
  late String expectedMainOutput;
  late String expectedEnOutput;
  late String expectedDeOutput;
  late String expectedDeDeOutput;

  setUpAll(() {
    runSetupAll();
  });

  setUp(() {
    enInput = loadResource('main/fallback_region_en.json');
    deInput = loadResource('main/fallback_region_de.json');
    deDeInput = loadResource('main/fallback_region_de_de.json');
    buildYaml = loadResource('main/build_config.yaml');
    expectedMainOutput =
        loadResource('main/_expected_fallback_region_main.output');
    expectedEnOutput = loadResource('main/_expected_fallback_region_en.output');
    expectedDeOutput = loadResource('main/_expected_fallback_region_de.output');
    expectedDeDeOutput =
        loadResource('main/_expected_fallback_region_de_de.output');
  });

  // The region locale "de-DE" is a super set of its parent locale "de".
  // It only specifies overrides and inherits everything else from "de",
  // which in turn falls back to the base locale "en".
  test('region extension inherits from parent locale', () {
    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!.copyWith(
        fallbackStrategy: FallbackStrategy.baseLocale,
      ),
      translationMap: TranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: JsonDecoder().decode(enInput),
        )
        ..addTranslations(
          locale: I18nLocale.fromString('de'),
          translations: JsonDecoder().decode(deInput),
        )
        ..addTranslations(
          locale: I18nLocale.fromString('de-DE'),
          translations: JsonDecoder().decode(deDeInput),
        ),
      inputDirectoryHint: 'fake/path/integration',
    );

    expect(result.main, expectedMainOutput);
    expect(result.translations[I18nLocale.fromString('en')], expectedEnOutput);
    expect(result.translations[I18nLocale.fromString('de')], expectedDeOutput);
    expect(
      result.translations[I18nLocale.fromString('de-DE')],
      expectedDeDeOutput,
    );
  });
}
