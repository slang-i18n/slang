import 'package:slang/builder/builder/raw_config_builder.dart';
import 'package:slang/builder/decoder/csv_decoder.dart';
import 'package:slang/builder/generator_facade.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/translation_map.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

void main() {
  late String compactInput;
  late String buildYaml;
  late String expectedOutput;

  setUp(() {
    compactInput = loadResource('main/csv_compact.csv');
    buildYaml = loadResource('main/build_config.yaml');
    expectedOutput = loadResource('main/expected_single.output');
  });

  test('compact csv', () {
    final parsed = CsvDecoder().decode(compactInput);

    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!,
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
    );

    expect(result.joinAsSingleOutput(), expectedOutput);
  });
}
