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
          namespace: 'errors',
          translations: {
            'empty': 'Cannot be empty',
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

    final root = data.root.entries;
    expect(root['appName'], isA<TextNode>());
    expect(root['errors'], isA<ObjectNode>());
    expect(
      (root['errors'] as ObjectNode).entries['empty'],
      isA<TextNode>(),
    );
  });
}
