import 'package:slang/src/builder/builder/translation_model_list_builder.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/node.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:test/test.dart';

void main() {
  test('Should handle default namespace', () {
    final result = TranslationModelListBuilder.build(
      RawConfig.defaultConfig.copyWith(
        namespaces: true,
      ),
      TranslationMap()
        ..addTranslations(
          locale: I18nLocale(language: 'en'),
          namespace: 'l1',
          translations: {
            'l2': 'Cannot be empty',
          },
        )
        ..addTranslations(
          locale: I18nLocale(language: 'en'),
          namespace: RegexUtils.defaultNamespace,
          translations: {
            'appName': 'TestApp',
          },
        ),
    );

    expect(result.length, 1);

    final data = result.first;
    expect(data.locale, I18nLocale(language: 'en'));
    expect(data.root.entries.length, 2);

    final l1 = data.root.entries;
    expect(l1['appName'], isA<TextNode>());
    expect(l1['l1'], isA<ObjectNode>());
    expect((l1['l1'] as ObjectNode).entries['l2'], isA<TextNode>());
  });

  test('Should handle nested namespaces', () {
    final result = TranslationModelListBuilder.build(
      RawConfig.defaultConfig.copyWith(
        namespaces: true,
      ),
      TranslationMap()
        ..addTranslations(
          locale: I18nLocale(language: 'en'),
          namespace: 'l1.l2.l3',
          translations: {
            'title': 'Deep Title',
          },
        )
        ..addTranslations(
          locale: I18nLocale(language: 'en'),
          namespace: 'l1.l2b',
          translations: {
            'title': 'Third Title',
          },
        )
        ..addTranslations(
          locale: I18nLocale(language: 'en'),
          namespace: RegexUtils.defaultNamespace,
          translations: {
            'appName': 'TestApp',
          },
        ),
    );

    expect(result.length, 1);

    final data = result.first;
    expect(data.locale, I18nLocale(language: 'en'));
    expect(data.root.entries.length, 2);

    final l1 = data.root.entries;
    expect(l1['appName'], isA<TextNode>());
    expect(l1['l1'], isA<ObjectNode>());

    final l2 = (l1['l1'] as ObjectNode).entries;
    expect(l2.length, 2);
    expect(l2['l2b'], isA<ObjectNode>());
    expect(l2['l2'], isA<ObjectNode>());
    expect((l2['l2b'] as ObjectNode).entries['title'], isA<TextNode>());

    final l3 = (l2['l2'] as ObjectNode).entries;
    expect(l3['l3'], isA<ObjectNode>());
    expect((l3['l3'] as ObjectNode).entries['title'], isA<TextNode>());
  });
}
