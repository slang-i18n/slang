import 'package:fast_i18n/builder/builder/build_config_builder.dart';
import 'package:fast_i18n/builder/decoder/json_decoder.dart';
import 'package:fast_i18n/builder/generator_facade.dart';
import 'package:fast_i18n/builder/model/i18n_locale.dart';
import 'package:fast_i18n/builder/model/namespace_translation_map.dart';
import 'package:test/test.dart';

import '../../util/build_config_utils.dart';
import '../../util/resources_utils.dart';

void main() {
  late String input;
  late String buildYaml;
  late String expectedOutput;

  setUp(() {
    input = loadResource('main/json_simple.json');
    buildYaml = loadResource('main/build_config.yaml');
    expectedOutput = loadResource('main/expected_no_flutter.output');
  });

  test('no flutter', () {
    final result = GeneratorFacade.generate(
      buildConfig: BuildConfigBuilder.fromYaml(buildYaml)!.copyWith(
        flutterIntegration: false,
      ),
      baseName: 'translations',
      translationMap: NamespaceTranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: JsonDecoder().decode(input),
        ),
    );

    expect(result.joinAsSingleOutput(), expectedOutput);
  });
}
