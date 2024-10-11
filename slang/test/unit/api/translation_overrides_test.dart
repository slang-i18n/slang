import 'package:slang/src/api/locale.dart';
import 'package:slang/src/api/singleton.dart';
import 'package:slang/src/api/translation_overrides.dart';
import 'package:slang/src/builder/builder/build_model_config_builder.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:test/test.dart';

void main() {
  group('string', () {
    test('Should return a plain string', () async {
      final meta = await _buildMetaWithOverrides({
        'aboutPage.title': 'About',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {});
      expect(parsed, 'About');
    });

    test('Should not escape new line', () async {
      final meta = await _buildMetaWithOverrides({
        'aboutPage.title': 'About\nPage',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {});
      expect(parsed, 'About\nPage');
    });

    test('Should return a plain string without escaping', () async {
      final meta = await _buildMetaWithOverrides({
        'aboutPage.title': 'About \' \$ {arg}',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {});
      expect(parsed, 'About \' \$ {arg}');
    });

    test('Should return an interpolated string', () async {
      final meta = await _buildMetaWithOverrides({
        'aboutPage.title': r'About ${arg}',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'arg': 'Page',
      });
      expect(parsed, 'About Page');
    });

    test('Should ignore type in interpolated string', () async {
      final meta = await _buildMetaWithOverrides({
        'aboutPage.title': r'About ${arg: int}',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'arg': 'Page',
      });
      expect(parsed, 'About Page');
    });

    test('Should return an interpolated string with dollar only', () async {
      final meta = await _buildMetaWithOverrides({
        'aboutPage.title': r'About $arg',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'arg': 'Page',
      });
      expect(parsed, 'About Page');
    });
  });
}

Future<TranslationMetadata<FakeAppLocale, FakeTranslations>>
    _buildMetaWithOverrides(
  Map<String, dynamic> overrides,
) async {
  final utils = _Utils();
  final translations = await utils.buildWithOverridesFromMap(
    locale: FakeAppLocale(languageCode: 'und'),
    isFlatMap: false,
    map: overrides,
  );
  return translations.$meta;
}

class _Utils extends BaseAppLocaleUtils<FakeAppLocale, FakeTranslations> {
  _Utils()
      : super(
          baseLocale: FakeAppLocale(languageCode: 'und'),
          locales: [FakeAppLocale(languageCode: 'und')],
          buildConfig: _defaultConfig,
        );
}

final _defaultConfig = RawConfig.defaultConfig.toBuildModelConfig();
