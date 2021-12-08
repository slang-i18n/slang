import 'package:fast_i18n/src/builder/build_config_builder.dart';
import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:fast_i18n/src/generator/generator_facade.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/namespace_translation_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/assets_utils.dart';
import '../util/datetime_utils.dart';

void main() {
  late String csvCompactContent;
  late String csvEnContent;
  late String csvDeContent;
  late String expectedOutput;
  late String buildConfigContent;

  setUp(() {
    csvCompactContent = loadAsset('csv_compact.csv');
    csvEnContent = loadAsset('csv_en.csv');
    csvDeContent = loadAsset('csv_de.csv');
    expectedOutput = loadAsset('expected.output');
    buildConfigContent = loadAsset('build_config.yaml');
  });

  group('csv', () {
    test('compact csv', () {
      final parsed = TranslationMapBuilder.fromString(
        FileType.csv,
        csvCompactContent,
      );

      final buildConfig = BuildConfigBuilder.fromYaml(buildConfigContent)!;

      final result = GeneratorFacade.generate(
        buildConfig: buildConfig,
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

    test('separated csv', () {
      final parsedEn = TranslationMapBuilder.fromString(
        FileType.csv,
        csvEnContent,
      );

      final parsedDe = TranslationMapBuilder.fromString(
        FileType.csv,
        csvDeContent,
      );

      final buildConfig = BuildConfigBuilder.fromYaml(buildConfigContent)!;

      final result = GeneratorFacade.generate(
        buildConfig: buildConfig,
        baseName: 'translations',
        translationMap: NamespaceTranslationMap()
          ..add(
            locale: I18nLocale.fromString('en'),
            namespace: '',
            translations: parsedEn,
          )
          ..add(
            locale: I18nLocale.fromString('de'),
            namespace: '',
            translations: parsedDe,
          ),
        showPluralHint: false,
        now: birthDate,
      );

      expect(result, expectedOutput);
    });
  });
}
