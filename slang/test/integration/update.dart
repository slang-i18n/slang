import 'package:slang/builder/builder/raw_config_builder.dart';
import 'package:slang/builder/decoder/json_decoder.dart';
import 'package:slang/builder/generator_facade.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/translation_map.dart';
import 'package:slang/builder/utils/file_utils.dart';

import '../util/config_utils.dart';
import '../util/resources_utils.dart';

/// To run this:
/// -> dart test/integration/update.dart
///
/// Generates expected integration results
/// Using JSON files only.
void main() {
  print('Generate integration test results...');
  print('');

  final en = loadResource('main/json_en.json');
  final de = loadResource('main/json_de.json');
  final simple = loadResource('main/json_simple.json');
  final buildConfig =
      RawConfigBuilder.fromYaml(loadResource('main/build_config.yaml'))!;
  generateMainIntegration(buildConfig, en, de);
  generateMainSplitIntegration(buildConfig, en, de);
  generateNoFlutter(buildConfig, simple);
  generateNoLocaleHandling(buildConfig, simple);

  print('');
}

void generateMainIntegration(RawConfig buildConfig, String en, String de) {
  final result = GeneratorFacade.generate(
    rawConfig: buildConfig,
    baseName: 'translations',
    translationMap: TranslationMap()
      ..addTranslations(
        locale: I18nLocale.fromString('en'),
        translations: JsonDecoder().decode(en),
      )
      ..addTranslations(
        locale: I18nLocale.fromString('de'),
        translations: JsonDecoder().decode(de),
      ),
  ).joinAsSingleOutput();

  _write(
    path: 'main/expected_single',
    content: result,
  );
}

void generateMainSplitIntegration(
  RawConfig buildConfig,
  String en,
  String de,
) {
  final result = GeneratorFacade.generate(
    rawConfig: buildConfig.copyWith(outputFormat: OutputFormat.multipleFiles),
    baseName: 'translations',
    translationMap: TranslationMap()
      ..addTranslations(
        locale: I18nLocale.fromString('en'),
        translations: JsonDecoder().decode(en),
      )
      ..addTranslations(
        locale: I18nLocale.fromString('de'),
        translations: JsonDecoder().decode(de),
      ),
  );

  _write(
    path: 'main/expected_main',
    content: result.header,
  );

  _write(
    path: 'main/expected_en',
    content: result.translations[I18nLocale.fromString('en')]!,
  );

  _write(
    path: 'main/expected_de',
    content: result.translations[I18nLocale.fromString('de')]!,
  );

  _write(
    path: 'main/expected_map',
    content: result.flatMap!,
  );
}

void generateNoFlutter(RawConfig buildConfig, String simple) {
  final result = GeneratorFacade.generate(
    rawConfig: buildConfig.copyWith(flutterIntegration: false),
    baseName: 'translations',
    translationMap: TranslationMap()
      ..addTranslations(
        locale: I18nLocale.fromString('en'),
        translations: JsonDecoder().decode(simple),
      ),
  ).joinAsSingleOutput();

  _write(
    path: 'main/expected_no_flutter',
    content: result,
  );
}

void generateNoLocaleHandling(RawConfig buildConfig, String simple) {
  final result = GeneratorFacade.generate(
    rawConfig: buildConfig.copyWith(renderLocaleHandling: false),
    baseName: 'translations',
    translationMap: TranslationMap()
      ..addTranslations(
        locale: I18nLocale.fromString('en'),
        translations: JsonDecoder().decode(simple),
      ),
  ).joinAsSingleOutput();

  _write(
    path: 'main/expected_no_locale_handling',
    content: result,
  );
}

void _write({
  required String path,
  required String content,
}) {
  final finalPath = 'test/integration/resources/$path.output';
  print(' -> $finalPath');
  FileUtils.writeFile(path: finalPath, content: content);
}
