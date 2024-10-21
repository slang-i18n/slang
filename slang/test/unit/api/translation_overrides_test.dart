import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'package:slang/src/api/locale.dart';
import 'package:slang/src/api/singleton.dart';
import 'package:slang/src/api/translation_overrides.dart';
import 'package:slang/src/builder/builder/build_model_config_builder.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    initializeDateFormatting();
  });

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

    test('Should return string with custom DateFormat', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title': r"About ${date: DateFormat('dd-MM')}",
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'date': DateTime(2022, 3, 12),
      });
      expect(parsed, 'About 12-03');
    });

    test('Should return string with built-in DateFormat', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title': r'About ${date: yMd}',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'date': DateTime(2022, 3, 12),
      });
      expect(parsed, 'About 3/12/2022');
    });

    test('Should return string with predefined type', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title': r'About ${date: predefined}',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'date': DateTime(2022, 3, 12),
      });
      expect(parsed, 'About 2022');
    });

    test('Should return string with custom NumberFormat', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title': r'About ${number: NumberFormat("000.##")}',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'number': 3.14,
      });
      expect(parsed, 'About 003.14');
    });

    test('Should return string with built-in NumberFormat', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title': r'About ${number: decimalPattern}',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'number': 3.14,
      });
      expect(parsed, 'About 3.14');
    });

    test('Should return string with built-in NumberFormat with parameters', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title':
            r'About ${number: NumberFormat.currency(symbol: "RR")}',
      });
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'number': 3.14,
      });
      expect(parsed, 'About RR3.14');
    });

    test('Should return string with NumberFormat with parameters in DE', () {
      final meta = _buildMetaWithOverrides({
        'aboutPage.title':
            r'About ${number: NumberFormat.currency(symbol: "RR")}',
      }, locale: 'de');
      final parsed = TranslationOverrides.string(meta, 'aboutPage.title', {
        'number': 3.14,
      });
      expect(parsed, 'About 3,14 RR');
    });
  });
}

TranslationMetadata<FakeAppLocale, FakeTranslations> _buildMetaWithOverrides(
  Map<String, dynamic> overrides, {
  String? locale,
}) {
  final utils = _Utils();
  final translations = utils.buildWithOverridesFromMapSync(
    locale: FakeAppLocale(languageCode: locale ?? 'en', types: {
      'predefined': ValueFormatter(() => DateFormat('yyyy')),
    }),
    isFlatMap: false,
    map: overrides,
  );
  return translations.$meta;
}

class _Utils extends BaseAppLocaleUtils<FakeAppLocale, FakeTranslations> {
  _Utils()
      : super(
          baseLocale: FakeAppLocale(languageCode: 'en'),
          locales: [FakeAppLocale(languageCode: 'en')],
          buildConfig: _defaultConfig,
        );
}

final _defaultConfig = RawConfig.defaultConfig.toBuildModelConfig();
