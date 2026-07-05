import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/runner/configure.dart';
import 'package:test/test.dart';

TranslationFile _file(String locale, [String content = '']) {
  return TranslationFile(
    path: '',
    locale: I18nLocale.fromString(locale),
    namespace: RegexUtils.defaultNamespace,
    read: () async => content,
  );
}

void main() {
  group('getLocales', () {
    test('Should return sorted locale list', () async {
      final locales = await getLocales(SlangFileCollection(
        config: RawConfig.defaultConfig,
        files: [
          _file('en'),
          _file('zh'),
          _file('de'),
          _file('de'),
          _file('fr-FR'),
        ],
      ));

      expect(locales, [
        I18nLocale.fromString('de'),
        I18nLocale.fromString('en'),
        I18nLocale.fromString('fr-FR'),
        I18nLocale.fromString('zh'),
      ]);
    });

    test('Should return locales within compact csv', () async {
      final locales = await getLocales(SlangFileCollection(
        config: RawConfig.defaultConfig.copyWith(
          inputFilePattern: '.csv',
        ),
        files: [
          _file('en', 'key,en,de,fr\nhello,Hello,Hallo,Bonjour'),
        ],
      ));

      expect(locales, [
        I18nLocale.fromString('de'),
        I18nLocale.fromString('en'),
        I18nLocale.fromString('fr'),
      ]);
    });
  });

  group('updatePlist', () {
    test('Should adapt tab style', () {
      final locales = {
        I18nLocale.fromString('de'),
        I18nLocale.fromString('en'),
        I18nLocale.fromString('fr-FR'),
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

      final result = updatePlist(
        locales: locales,
        content: content,
      );
      expect(result, expected);
    });
  });
}
