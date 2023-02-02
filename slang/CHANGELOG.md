## 3.11.1

- fix: missing unused translations in secondary locales

## 3.11.0

- feat: add `(ignoreMissing)` and `(ignoreUnused)` modifiers which changes the behaviour of `flutter pub run slang analyze`

## 3.10.0

- feat: there is now a default plural resolver so the app keeps working in production when you forgot to define one, you will only see a warning in the log
- fix: `key_map_case` should work with `(map)` modifier

## 3.9.0

- feat: improve interface attribute inference algorithm
- feat: generate to `lib/gen/<filename>` in Flutter environment by default if input is outside of `lib/` and no output directory is given

## 3.8.0

- feat: add `(interface=<Interface>)` and `(singleInterface=<Interface>)` modifiers, a new approach to configure interfaces without touching the config file
- feat: add `AppLocaleUtils.supportedLocales` and `AppLocaleUtils.supportedLocalesRaw`, this API works in `locale_handling: false`
- fix: possible class name conflict for objects inside lists
- **DEPRECATED:** `LocaleSettings.supportedLocales` and `LocaleSettings.supportedLocalesRaw`

## 3.7.0

- feat: official web support

## 3.6.0

- feat: RichText supports links inside default translation
- feat: `flutter pub run slang watch` works recursively and does not crash on error

## 3.5.0

- feat: csv decoding now support both `CRLF` and `LF`, `"` and `'`
- fix: `LocaleSettings.setPluralResolver` should not throw an assertion error
- fix: `flutter pub run slang migrate` should also work without `:` in command

## 3.4.0

- feat: add `--locale=<locale>` argument to `flutter pub run slang apply` to only apply a specific locale
- **BREAKING (TOOL):** `--flat` argument for `flutter pub run slang analyze` and `apply` is no longer available

## 3.3.1

- fix: when namespaces are used, consider more directories (not only parent) for locale detection (e.g. `assets/i18n/en-US/pages/home.json`)

## 3.3.0

- feat: `flutter pub run slang analyze` now also checks unused translations (on top of missing translations)
- docs: prefer `slang analyze` over `slang:analyze` (and for all other commands); both styles are supported however

## 3.2.0

- feat: add command `flutter pub run slang:apply` to add translations from the `slang:analyze` result
- fix: handle `isFlatMap` parameter when overriding translations correctly
- fix: update arb migration tool to respect new modifier syntax

## 3.1.0

- feat: add command `flutter pub run slang:analyze` to report missing translations

## 3.0.0

**Translation Overrides and Enhanced Modifiers**

- feat: it is now possible to override translations via `LocaleSettings.overrideTranslations` (checkout updated README)
- feat: there is a new modifier syntax which allows for multiple modifiers e.g. `myKey(plural, rich)`
- feat: improve file scan (now only checks top-level directory for any config files)
- **Breaking:** default plural parameter is now `n`; you can revert this by setting `pluralization`/`default_parameter: count`
- **Breaking:** custom plural/context parameter must follow syntax `apples(param=appleCount)`

All breaking changes will result in a compile-time error, so don't worry for "hidden" bugs :)

You can read the detailed migration guide [here](https://github.com/Tienisto/slang/blob/master/slang/MIGRATION.md).

## 2.8.0

- feat: add `AppLocaleUtils.parseLocaleParts`
- fix: `LocaleSettings.useDeviceLocale` now does not complain of weird locales on Linux
- fix: rich text now handles all characters
- fix: rich text properly applies param_case
- fix: empty nodes are rendered as classes instead of claiming them as plurals

## 2.7.0

- feat: ignore empty plural / context nodes when `fallback_strategy: base_locale` is used
- feat: add `coverage:ignore-file` to generated file and ignore every lint

## 2.6.2

- feat: add Russian plural resolver (thanks to @LuckyWins)
- fix: parse rich text with interpolation `braces` and `double_braces` correctly

## 2.6.1

- fix: remove `const` if rich text has links

## 2.6.0

- feat: render context enum values as is, instead of forcing to camel case
- feat: add additional lint ignores to generated file
- fix: generate correct ordinal (plural) call
- fix: handle rich texts containing linked translations

## 2.5.0

- feat: add extension method shorthand (e.g. `context.tr.someKey.anotherKey`)
- feat: add `LocaleSettings.getLocaleStream` to keep track of every locale change
- feat: return more specific `TextSpan` instead of `InlineSpan` for rich texts

## 2.4.1

- fix: do not export `package:flutter/widgets.dart`

## 2.4.0

- feat: allow external enums for context feature (add `generate_enum` and `imports` config)
- feat: add default context parameter name (`default_parameter`)
- feat: add export statement in generated file to avoid imports of extension methods

## 2.3.1

- fix: add missing fallback for flat map if configured

## 2.3.0

- feat: use tight version for `slang_flutter` and `slang_build_runner`
- fix: throw error if base locale not found
- fix: `TranslationProvider` should use current locale
- fix: use more strict locale regex to avoid false-positives when detecting locale of directory name

## 2.2.0

- feat: locale can be moved from file name to directory name (e.g. `i18n/fr/page1_fr.i18n.json` to `i18n/fr/page1.i18n.json`)

## 2.1.0

- feat: add `slang.yaml` support which has less boilerplate than `build.yaml`
- fix: move internal `build.yaml` to correct package

## 2.0.0

**Transition to a federated package structure**

- **Breaking:** rebranding to `slang`
- **Breaking:** add `slang_build_runner`, `slang_flutter` depending on your use case
- **Breaking:** remove `output_file_pattern` (was deprecated)
- feat: dart-only support (`flutter_integration: false`)
- feat: multiple package support
- feat: RichText support

Thanks to [@fzyzcjy](https://github.com/fzyzcjy).

You can read the detailed migration guide [here](https://github.com/Tienisto/slang/blob/master/slang/MIGRATION.md).
