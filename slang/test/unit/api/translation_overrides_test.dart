import 'package:slang/api/locale.dart';
import 'package:slang/api/singleton.dart';
import 'package:slang/api/translation_overrides.dart';
import 'package:slang/builder/builder/build_model_config_builder.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:test/test.dart';

void main() {
  group('string', () {
    test('Should return a plain string', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title': 'About',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {});
      expect(parsed, 'About');
    });

    test('Should not escape new line', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title': 'About\nPage',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {});
      expect(parsed, 'About\nPage');
    });

    test('Should return a plain string without escaping', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title': 'About \' \$ {arg}',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {});
      expect(parsed, 'About \' \$ {arg}');
    });

    test('Should return an interpolated string', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title': r'About ${arg}',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'arg': 'Page',
      });
      expect(parsed, 'About Page');
    });

    test('Should ignore type in interpolated string', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title': r'About ${arg: int}',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'arg': 'Page',
      });
      expect(parsed, 'About Page');
    });

    test('Should return an interpolated string with dollar only', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title': r'About $arg',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'arg': 'Page',
      });
      expect(parsed, 'About Page');
    });
  });
}

TranslationMetadata<FakeAppLocale, FakeTranslations> _buildMetaWithOverrides(
  Map<String, dynamic> overrides,
) {
  final utils = _Utils();
  return utils
      .buildWithOverridesFromMap(
        locale: FakeAppLocale(languageCode: 'und'),
        isFlatMap: false,
        map: overrides,
      )
      .$meta;
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
