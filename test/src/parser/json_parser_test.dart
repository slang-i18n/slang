import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:fast_i18n/src/parser/json_parser.dart';
import 'package:test/test.dart';

void main() {
  final defaultLocale = I18nLocale.fromString(BuildConfig.defaultBaseLocale);
  final baseConfig = BuildConfig(
    baseLocale: defaultLocale,
    fallbackStrategy: BuildConfig.defaultFallbackStrategy,
    inputDirectory: BuildConfig.defaultInputDirectory,
    inputFilePattern: BuildConfig.defaultInputFilePattern,
    outputDirectory: BuildConfig.defaultOutputDirectory,
    outputFilePattern: BuildConfig.defaultOutputFilePattern,
    translateVar: BuildConfig.defaultTranslateVar,
    enumName: BuildConfig.defaultEnumName,
    translationClassVisibility: BuildConfig.defaultTranslationClassVisibility,
    keyCase: BuildConfig.defaultKeyCase,
    stringInterpolation: BuildConfig.defaultStringInterpolation,
    renderFlatMap: BuildConfig.defaultRenderFlatMap,
    maps: BuildConfig.defaultMaps,
    pluralAuto: BuildConfig.defaultPluralAuto,
    pluralCardinal: BuildConfig.defaultCardinal,
    pluralOrdinal: BuildConfig.defaultOrdinal,
    contexts: BuildConfig.defaultContexts,
  );

  group(JsonParser.parseTranslations, () {
    test('one text', () {
      final root = JsonParser.parseTranslations(baseConfig, defaultLocale, '''{
        "hi": "hello"
      }''').root;
      expect(root.entries.length, 1);
      expect(root.entries.entries.first.key, 'hi');
      expect(root.entries.entries.first.value, isA<TextNode>());
      expect((root.entries.entries.first.value as TextNode).content, 'hello');
      expect((root.entries.entries.first.value as TextNode).params, []);
    });

    test('root map', () {
      final config = baseConfig.copyWith(maps: ['myMap']);
      final root = JsonParser.parseTranslations(config, defaultLocale, '''{
        "hi": "hello",
        "myMap": {
          "a": "a"
        }
      }''').root;
      expect(root.entries.length, 2);
      expect(root.entries.entries.first.value, isA<TextNode>());
      expect(root.entries.entries.last.value, isA<ObjectNode>());
      expect(root.entries.entries.last.key, 'myMap');
      expect((root.entries.entries.last.value as ObjectNode).type,
          ObjectNodeType.map);
      expect(
          (root.entries.entries.last.value as ObjectNode).plainStrings, true);
    });

    test('root list', () {
      final root = JsonParser.parseTranslations(baseConfig, defaultLocale, '''{
        "hi": "hello",
        "myList": [
          "a"
        ]
      }''').root;
      expect(root.entries.length, 2);
      expect(root.entries.entries.first.value, isA<TextNode>());
      expect(root.entries.entries.last.value, isA<ListNode>());
      expect((root.entries.entries.last.value as ListNode).entries.length, 1);
      expect((root.entries.entries.last.value as ListNode).plainStrings, true);
    });
  });
}

extension on BuildConfig {
  BuildConfig copyWith({
    List<String>? maps,
    PluralAuto? pluralAuto,
    List<String>? pluralCardinal,
    List<String>? pluralOrdinal,
  }) {
    return BuildConfig(
      baseLocale: baseLocale,
      fallbackStrategy: fallbackStrategy,
      inputDirectory: inputDirectory,
      inputFilePattern: inputFilePattern,
      outputDirectory: outputDirectory,
      outputFilePattern: outputFilePattern,
      translateVar: translateVar,
      enumName: enumName,
      translationClassVisibility: translationClassVisibility,
      keyCase: keyCase,
      stringInterpolation: stringInterpolation,
      renderFlatMap: renderFlatMap,
      maps: maps ?? this.maps,
      pluralAuto: pluralAuto ?? this.pluralAuto,
      pluralCardinal: pluralCardinal ?? this.pluralCardinal,
      pluralOrdinal: pluralOrdinal ?? this.pluralOrdinal,
      contexts: BuildConfig.defaultContexts,
    );
  }
}
