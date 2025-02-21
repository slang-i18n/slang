import 'package:slang/src/api/locale.dart';
import 'package:slang/src/api/singleton.dart';
import 'package:slang/src/api/state.dart';
import 'package:slang/src/builder/model/build_model_config.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/sanitization_config.dart';
import 'package:test/test.dart';

void main() {
  group('setPluralResolver', () {
    setUp(() {
      GlobalLocaleState.instance.setLocale(_baseLocale);
    });

    test('should set overrides to null when it is previously empty', () {
      final localeSettings = _LocaleSettings();

      localeSettings.setPluralResolver(
        language: 'und',
        cardinalResolver: (n, {zero, one, two, few, many, other}) {
          return other!;
        },
      );

      expect(localeSettings.currentTranslations.providedNullOverrides, true);
    });

    test('should keep overrides when it is previously not empty', () async {
      final localeSettings = _LocaleSettings();

      await localeSettings.overrideTranslationsFromMap(
        locale: _baseLocale,
        isFlatMap: false,
        map: {'hello': 'hi'},
      );

      await localeSettings.setPluralResolver(
        language: 'und',
        cardinalResolver: (n, {zero, one, two, few, many, other}) {
          return other!;
        },
      );

      expect(localeSettings.currentTranslations.providedNullOverrides, false);
      expect(
        localeSettings.currentTranslations.$meta.overrides.keys,
        ['hello'],
      );
    });
  });
}

final _baseLocale = FakeAppLocale(languageCode: 'und');

class _AppLocaleUtils
    extends BaseAppLocaleUtils<FakeAppLocale, FakeTranslations> {
  _AppLocaleUtils()
      : super(
          baseLocale: _baseLocale,
          locales: [_baseLocale],
          buildConfig: BuildModelConfig(
            fallbackStrategy: FallbackStrategy.none,
            keyCase: null,
            keyMapCase: null,
            paramCase: null,
            sanitization: SanitizationConfig(
              enabled: true,
              prefix: 'k',
              caseStyle: CaseStyle.camel,
            ),
            stringInterpolation: StringInterpolation.braces,
            maps: [],
            pluralAuto: PluralAuto.cardinal,
            pluralParameter: 'n',
            pluralCardinal: [],
            pluralOrdinal: [],
            contexts: [],
            interfaces: [],
            generateEnum: true,
          ),
        );
}

class _LocaleSettings
    extends BaseLocaleSettings<FakeAppLocale, FakeTranslations> {
  _LocaleSettings() : super(utils: _AppLocaleUtils(), lazy: false);
}
