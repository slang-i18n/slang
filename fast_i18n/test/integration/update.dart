import 'package:fast_i18n/builder/builder/build_config_builder.dart';
import 'package:fast_i18n/builder/decoder/json_decoder.dart';
import 'package:fast_i18n/builder/generator_facade.dart';
import 'package:fast_i18n/builder/model/build_config.dart';
import 'package:fast_i18n/builder/model/i18n_locale.dart';
import 'package:fast_i18n/builder/model/namespace_translation_map.dart';
import 'package:fast_i18n/builder/utils/file_utils.dart';

import '../util/build_config_utils.dart';
import '../util/resources_utils.dart';

/// To run this:
/// -> dart test/integration/update.dart
///
/// Generates expected integration results
/// Using JSON files only.
void main() {
  final en = loadResource('main/json_en.json');
  final de = loadResource('main/json_de.json');
  final simple = loadResource('main/json_simple.json');
  final buildConfig =
      BuildConfigBuilder.fromYaml(loadResource('main/build_config.yaml'))!;
  generateMainIntegration(buildConfig, en, de);
  generateMainSplitIntegration(buildConfig, en, de);
  generateNoFlutter(buildConfig, simple);
  generateNoLocaleHandling(buildConfig, simple);
}

void generateMainIntegration(BuildConfig buildConfig, String en, String de) {
  final result = GeneratorFacade.generate(
    buildConfig: buildConfig,
    baseName: 'translations',
    translationMap: NamespaceTranslationMap()
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
  BuildConfig buildConfig,
  String en,
  String de,
) {
  final result = GeneratorFacade.generate(
    buildConfig: buildConfig.copyWith(outputFormat: OutputFormat.multipleFiles),
    baseName: 'translations',
    translationMap: NamespaceTranslationMap()
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

void generateNoFlutter(BuildConfig buildConfig, String simple) {
  final result = GeneratorFacade.generate(
    buildConfig: buildConfig.copyWith(flutterIntegration: false),
    baseName: 'translations',
    translationMap: NamespaceTranslationMap()
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

void generateNoLocaleHandling(BuildConfig buildConfig, String simple) {
  final result = GeneratorFacade.generate(
    buildConfig: buildConfig.copyWith(renderLocaleHandling: false),
    baseName: 'translations',
    translationMap: NamespaceTranslationMap()
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
  FileUtils.writeFile(
      path: 'test/integration/resources/$path.output', content: content);
}
