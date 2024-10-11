import 'package:slang/src/builder/decoder/json_decoder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

void main() {
  late String input;
  late String expectedEnOutput;

  setUp(() {
    input = loadResource('main/json_rich_text.json');
    expectedEnOutput = loadResource(
      'main/_expected_rich_text.output',
    );
  });

  test('rich text', () {
    final result = GeneratorFacade.generate(
      rawConfig: RawConfig.defaultConfig.copyWith(
        renderTimestamp: false,
      ),
      translationMap: TranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: JsonDecoder().decode(input),
        ),
      inputDirectoryHint: 'fake/path/integration',
    );

    expect(result.translations[I18nLocale(language: 'en')], expectedEnOutput);
  });
}
