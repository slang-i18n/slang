import 'package:slang/src/builder/builder/raw_config_builder.dart';
import 'package:slang/src/builder/decoder/json_decoder.dart';
import 'package:slang/src/builder/generator_facade.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/translation_map.dart';

void main() {
  final enInput = '{"hello":"Hello","bye":"Goodbye","currency":{"symbol":"USD","name":"US Dollar"}}';
  final frInput = '{"hello":"Bonjour","bye":"Au revoir","currency":{"symbol":"EUR","name":"Euro"}}';
  final frTRInput = '{"currency":{"symbol":"TRY","name":"Turk Lirasi"}}';

  final result = GeneratorFacade.generate(
    rawConfig: RawConfigBuilder.fromYaml('''
targets:
  \$default:
    builders:
      slang_build_runner:
        options:
          base_locale: en
          input_file_pattern: .i18n.json
          output_file_name: translations.g.dart
          locale_handling: false
          timestamp: false
          flat_map: false
          string_interpolation: braces
          fallback_strategy: cascade
    ''')!,
    translationMap: TranslationMap()
      ..addTranslations(locale: I18nLocale.fromString('en'), translations: JsonDecoder().decode(enInput))
      ..addTranslations(locale: I18nLocale.fromString('fr'), translations: JsonDecoder().decode(frInput))
      ..addTranslations(locale: I18nLocale.fromString('fr-TR'), translations: JsonDecoder().decode(frTRInput)),
    inputDirectoryHint: 'fake/path/cascade',
  );

  for (final e in result.translations.entries) {
    print('=== ${e.key} ===');
    print(e.value);
  }
}
