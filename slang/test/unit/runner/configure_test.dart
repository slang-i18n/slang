import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/runner/configure.dart';
import 'package:test/test.dart';

void main() {
  group('getLocales', () {
    test('Should return sorted locale list', () {
      file(String locale) => TranslationFile(
            path: '',
            locale: I18nLocale(language: locale),
            namespace: RegexUtils.defaultNamespace,
            read: () async => '',
          );

      final locales = getLocales(SlangFileCollection(
        config: RawConfig.defaultConfig,
        files: [
          file('en'),
          file('zh'),
          file('de'),
          file('de'),
          file('fr-FR'),
        ],
      ));

      expect(locales, [
        I18nLocale(language: 'de'),
        I18nLocale(language: 'en'),
        I18nLocale(language: 'fr-FR'),
        I18nLocale(language: 'zh'),
      ]);
    });
  });

  group('updatePlist', () {
    test('Should adapt tab style', () {
      final locales = {
        I18nLocale(language: 'de'),
        I18nLocale(language: 'en'),
        I18nLocale(language: 'fr-FR'),
      };

      final content = '''
<dict>
-=-<key>a</key>
lol<key>b</key>
</dict>''';

      const expected = '''
<dict>
-=-<key>a</key>
lol<key>b</key>
-=-<key>CFBundleLocalizations</key>
-=-<array>
-=--=-<string>de</string>
-=--=-<string>en</string>
-=--=-<string>fr-FR</string>
-=-</array>
</dict>''';

      final result = updatePlist(locales: locales, content: content);
      expect(result, expected);
    });
  });
}
