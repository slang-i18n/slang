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
  late String buildYaml;

  setUpAll(() {
    runSetupAll();
  });

  setUp(() {
    buildYaml = loadResource('main/build_config.yaml');
  });

  test('region compose - fr + _TR creates fr-TR with cascade', () {
    final enInput = '''
{
  "hello": "Hello",
  "bye": "Goodbye",
  "currency": {
    "symbol": "USD",
    "name": "US Dollar"
  }
}
''';

    final frInput = '''
{
  "hello": "Bonjour",
  "bye": "Au revoir",
  "currency": {
    "symbol": "EUR",
    "name": "Euro"
  }
}
''';

    // Region file: only currency overrides, prefixed with _
    final regionTrInput = '''
{
  "currency": {
    "symbol": "TRY",
    "name": "Turk Lirasi"
  }
}
''';

    final translationMap = TranslationMap()
      ..addTranslations(
        locale: I18nLocale.fromString('en'),
        translations: JsonDecoder().decode(enInput),
      )
      ..addTranslations(
        locale: I18nLocale.fromString('fr'),
        translations: JsonDecoder().decode(frInput),
      )
      ..addTranslations(
        locale: I18nLocale.fromString('_TR'),
        translations: JsonDecoder().decode(regionTrInput),
      );

    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!.copyWith(
        fallbackStrategy: FallbackStrategy.cascade,
        outputFileName: 'translations.g.dart',
      ),
      translationMap: translationMap,
      inputDirectoryHint: 'fake/path/region_compose',
    );

    final mainOutput = result.main;
    final enOutput = result.translations[I18nLocale.fromString('en')]!;
    final frOutput = result.translations[I18nLocale.fromString('fr')]!;

    // _TR should NOT have its own generated class
    final trLocale = I18nLocale.fromString('_TR');
    expect(result.translations.containsKey(trLocale), isFalse,
        reason: 'Region file _TR should not produce a standalone class');

    // fr-TR should be composed and exist
    final frTrLocale = I18nLocale.fromString('fr-TR');
    expect(result.translations.containsKey(frTrLocale), isTrue,
        reason: 'fr-TR should be auto-composed from fr + _TR');
    final frTrOutput = result.translations[frTrLocale]!;

    // Enum should include fr-TR but NOT _TR (members are tab-indented on separate lines)
    expect(mainOutput, contains('AppLocale.en'));
    expect(mainOutput, contains('AppLocale.fr'));
    expect(mainOutput, contains('AppLocale.frTr'));
    expect(mainOutput, isNot(contains('AppLocale.tr')),
        reason: '_TR should not appear in the locale enum');

    // Base locale unchanged
    expect(enOutput, contains('typedef TranslationsEn = Translations;'));
    expect(enOutput, contains('\'USD\''));
    expect(enOutput, contains('\'Hello\''));

    // fr unchanged
    expect(frOutput, contains('class TranslationsFr extends Translations'));
    expect(frOutput, contains('\'Bonjour\''));
    expect(frOutput, contains('\'EUR\''));

    // fr-TR: extends fr (cascade to language parent)
    expect(frTrOutput, contains('class TranslationsFrTr extends TranslationsFr'));
    expect(frTrOutput, contains("import 'translations_fr.g.dart'"));

    // fr-TR: only contains region overrides, NOT inherited French strings
    expect(frTrOutput, isNot(contains('\'Bonjour\'')));
    expect(frTrOutput, isNot(contains('\'Au revoir\'')));

    // fr-TR: has Turkish currency (overridden from _TR)
    expect(frTrOutput, contains('\'TRY\''));
    expect(frTrOutput, contains('\'Turk Lirasi\''));

    // fr-TR: does NOT have English fallback values
    expect(frTrOutput, isNot(contains('\'USD\'')));
    expect(frTrOutput, isNot(contains('\'Hello\'')));

    // en-TR should also be composed (en + _TR)
    final enTrLocale = I18nLocale.fromString('en-TR');
    expect(result.translations.containsKey(enTrLocale), isTrue,
        reason: 'en-TR should be auto-composed from en + _TR');
    final enTrOutput = result.translations[enTrLocale]!;
    // Only region overrides; base keys inherited from en
    expect(enTrOutput, contains('\'TRY\''));
    expect(enTrOutput, isNot(contains('\'Hello\'')),
        reason: 'Base keys should be inherited, not duplicated');
    expect(enTrOutput, isNot(contains('\'Goodbye\'')));
    // en-TR extends base since en is the base locale
    expect(enTrOutput, contains('class TranslationsEnTr extends Translations'));
  });

  test('region compose - explicit locale wins over region composition', () {
    final enInput = '{"greeting": "Hello"}';
    final frInput = '{"greeting": "Bonjour"}';
    final explicitFrTrInput = '{"greeting": "Salut"}'; // explicit wins
    final regionTrInput = '{"greeting": "Merhaba"}';

    final translationMap = TranslationMap()
      ..addTranslations(
        locale: I18nLocale.fromString('en'),
        translations: JsonDecoder().decode(enInput),
      )
      ..addTranslations(
        locale: I18nLocale.fromString('fr'),
        translations: JsonDecoder().decode(frInput),
      )
      ..addTranslations(
        locale: I18nLocale.fromString('fr-TR'), // explicit file exists
        translations: JsonDecoder().decode(explicitFrTrInput),
      )
      ..addTranslations(
        locale: I18nLocale.fromString('_TR'),
        translations: JsonDecoder().decode(regionTrInput),
      );

    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!.copyWith(
        fallbackStrategy: FallbackStrategy.cascade,
        outputFileName: 'translations.g.dart',
      ),
      translationMap: translationMap,
      inputDirectoryHint: 'fake/path/region_compose',
    );

    final frTrOutput =
        result.translations[I18nLocale.fromString('fr-TR')]!;

    // Explicit file wins: greeting should be "Salut", not "Merhaba"
    expect(frTrOutput, contains('\'Salut\''));
    expect(frTrOutput, isNot(contains('\'Merhaba\'')));
  });
}
