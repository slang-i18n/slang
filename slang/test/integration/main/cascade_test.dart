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

  test('cascade fallback - fr-TR extends fr, fr extends en', () {
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

    final frTrInput = '''
{
  "currency": {
    "symbol": "TRY",
    "name": "Turk Lirasi"
  }
}
''';

    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!.copyWith(
        fallbackStrategy: FallbackStrategy.cascade,
      ),
      translationMap: TranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: JsonDecoder().decode(enInput),
        )
        ..addTranslations(
          locale: I18nLocale.fromString('fr'),
          translations: JsonDecoder().decode(frInput),
        )
        ..addTranslations(
          locale: I18nLocale.fromString('fr-TR'),
          translations: JsonDecoder().decode(frTrInput),
        ),
      inputDirectoryHint: 'fake/path/cascade',
    );

    final mainOutput = result.main;
    final enOutput = result.translations[I18nLocale.fromString('en')]!;
    final frOutput = result.translations[I18nLocale.fromString('fr')]!;
    final frTrOutput = result.translations[I18nLocale.fromString('fr-TR')]!;

    // Main file should define TranslationProvider, LocaleSettings, AppLocale
    expect(mainOutput, contains('AppLocale.en('));
    expect(mainOutput, contains('AppLocale.fr('));
    expect(mainOutput, contains('AppLocale.frTr('));
    expect(mainOutput, contains('fallbackStrategy: FallbackStrategy.cascade,'));

    // Base locale should have root Translations class
    expect(enOutput, contains('typedef TranslationsEn = Translations;'));
    expect(enOutput, contains('class TranslationsCurrencyEn'));
    expect(enOutput, contains('\'Hello\''));

    // fr should extend Translations (base)
    expect(frOutput, contains('class TranslationsFr extends Translations'));
    expect(frOutput, contains('class TranslationsCurrencyFr extends TranslationsCurrencyEn'));
    expect(frOutput, contains('TranslationsCurrencyFr.internal(TranslationsFr root) : this._root = root, super.internal(root)'));
    expect(frOutput, contains('\'Bonjour\''));
    expect(frOutput, contains('\'EUR\''));

    // fr-TR should extend TranslationsFr (not Translations)
    expect(frTrOutput, contains('class TranslationsFrTr extends TranslationsFr'));
    expect(frTrOutput, contains("import 'translations_fr.g.dart'"));
    expect(frTrOutput, contains('class TranslationsCurrencyFrTr extends TranslationsCurrencyFr'));
    expect(frTrOutput, contains('TranslationsCurrencyFrTr.internal(TranslationsFrTr root) : this._root = root, super.internal(root)'));
    expect(frTrOutput, contains('\'TRY\''));
    expect(frTrOutput, contains('\'Turk Lirasi\''));

    // fr-TR should NOT define keys it inherits from fr
    expect(frTrOutput, isNot(contains('\'Bonjour\'')));
    expect(frTrOutput, isNot(contains('\'Au revoir\'')));
    expect(frTrOutput, isNot(contains('\'Hello\'')));
    expect(frTrOutput, isNot(contains('\'Goodbye\'')));
  });

  test('cascade fallback - no language parent falls back to base locale', () {
    final enInput = '{"hello": "Hello"}';
    final deTrInput = '{"bye": "Tschuess"}';

    // de does NOT exist as a locale, so de-TR should fallback to base (en)
    final result = GeneratorFacade.generate(
      rawConfig: RawConfigBuilder.fromYaml(buildYaml)!.copyWith(
        fallbackStrategy: FallbackStrategy.cascade,
      ),
      translationMap: TranslationMap()
        ..addTranslations(
          locale: I18nLocale.fromString('en'),
          translations: JsonDecoder().decode(enInput),
        )
        ..addTranslations(
          locale: I18nLocale.fromString('de-TR'),
          translations: JsonDecoder().decode(deTrInput),
        ),
      inputDirectoryHint: 'fake/path/cascade',
    );

    final deTrOutput = result.translations[I18nLocale.fromString('de-TR')]!;

    // de-TR should extend Translations (base) since no de locale exists
    expect(deTrOutput, contains('class TranslationsDeTr extends Translations'));
  });
}
