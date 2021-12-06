import 'package:fast_i18n/src/builder/translation_map_builder.dart';
import 'package:fast_i18n/src/generator/generator_facade.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/interface.dart';
import 'package:fast_i18n/src/model/namespace_translation_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/assets_utils.dart';
import '../util/build_config_utils.dart';
import '../util/datetime_utils.dart';

void main() {
  late String correctCsvContent;
  late String wrongCsvContent;
  late String expectedOutput;

  setUp(() {
    correctCsvContent = loadAsset('csv/correct_order.csv');
    wrongCsvContent = loadAsset('csv/wrong_order.csv');
    expectedOutput = loadAsset('csv/correct_order_output.g.dart');
  });

  test('correct csv', () {
    final parsed = TranslationMapBuilder.fromString(
      FileType.csv,
      correctCsvContent,
    );

    final result = GeneratorFacade.generate(
      buildConfig: baseConfig.copyWith(
        inputFilePattern: '.csv',
        interfaces: [
          InterfaceConfig(
            name: 'PageData',
            attributes: {},
            paths: [
              InterfacePath('onboarding.pages.*'),
            ],
          ),
        ],
      ),
      baseName: 'strings',
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

  test('wrong csv', () {
    expect(() {
      return TranslationMapBuilder.fromString(
        FileType.csv,
        wrongCsvContent,
      );
    },
        throwsA(
            'The leaf "onboarding.pages.1.title" cannot be added because there are missing indices.'));
  });
}
