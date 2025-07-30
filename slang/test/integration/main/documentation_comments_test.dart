import 'package:slang/src/builder/decoder/json_decoder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

void main() {
  late String enInput;
  late String deInput;
  late String expectedEnOutput;

  setUp(() {
    enInput = loadResource('main/json_documentation_comments_en.json');
    deInput = loadResource('main/json_documentation_comments_de.json');
    expectedEnOutput = loadResource(
      'main/_expected_documentation_comments_en.output',
    );
  });

  test('documentation comments', () {
    final result = GeneratorFacade.generate(
      rawConfig: RawConfig.defaultConfig.copyWith(
        renderTimestamp: false,
        documentationComments: ['en', 'de'],
      ),
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

    expect(result.translations[I18nLocale(language: 'en')], expectedEnOutput);
  });
}
