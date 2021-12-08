import 'package:fast_i18n/src/builder/build_config_builder.dart';
import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:fast_i18n/src/generator/generator_facade.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/namespace_translation_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/assets_utils.dart';
import '../util/build_config_utils.dart';
import '../util/datetime_utils.dart';

void main() {
  late String csvContent;
  late String expectedOutput;
  late String buildConfigContent;

  setUp(() {
    csvContent = loadAsset('csv_compact.csv');
    expectedOutput = loadAsset('expected.output');
    buildConfigContent = loadAsset('build_config.yaml');
  });

  test('compact csv', () {
    final parsed = TranslationMapBuilder.fromString(
      FileType.csv,
      csvContent,
    );

    final buildConfig = BuildConfigBuilder.fromYaml(buildConfigContent)!;

    final result = GeneratorFacade.generate(
      buildConfig: buildConfig.copyWith(inputFilePattern: '.csv'),
      baseName: 'translations',
      translationMap: NamespaceTranslationMap()
        ..add(
          locale: I18nLocale.fromString('en'),
          namespace: '',
          translations: parsed['en'],
        )
        ..add(
          locale: I18nLocale.fromString('de'),
          namespace: '',
          translations: parsed['de'],
        ),
      showPluralHint: false,
      now: birthDate,
    );

    expect(result, expectedOutput);
  });
}
