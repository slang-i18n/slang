import 'package:slang/src/builder/builder/raw_config_builder.dart';
import 'package:slang/src/builder/decoder/json_decoder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

void main() {
  late String input;
  late String buildYaml;
  late String expectedMainOutput;

  setUp(() {
    input = loadResource('main/json_simple.json');
    buildYaml = loadResource('main/build_config.yaml');
    expectedMainOutput = loadResource('main/_expected_no_flutter.output');
  });

  test('no flutter', () {
    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!.copyWith(
        flutterIntegration: false,
      ),
      translationMap: TranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: JsonDecoder().decode(input),
        ),
      inputDirectoryHint: 'fake/path/integration',
    );

    expect(result.main, expectedMainOutput);
  });
}
