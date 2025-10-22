## 4.9.2

- fix: split flat map into multiple switch blocks instead of a HashMap which caused StackOverflow on linked translations (#319)

## 4.9.1

- fix: generate the flat map as a HashMap instead of a switch. Dart AOT compiler is unable to compile large switch statements (#318)

## 4.9.0

- feat: combine namespaced and non-namespaced translations (#311)
- feat: reduce CLI logging (#315)

## 4.8.1

- fix: remove new line in autodoc output

## 4.8.0

- feat: add `autodoc` feature enabled by default that generates the base translation as documentation for the translation keys (#218)
- feat: `slang analyze` supports `--source-dirs` (#309) @khoadng
- feat: `slang configure` supports `--source-dirs` (#308) @khoadng
- fix: correctly preserve identation of YAML output (#299) @adil192
- deps: loosen `build` constraint in `slang_build_runner` (#314)

## 4.7.3

- fix: add `override` to reserved keywords so it will be sanitized as well (#303)
- fix: do not generate empty classes (#305)

## 4.7.2

- fix: indentation of YAML output when using multiline strings (#299)

## 4.7.1

- fix: handle more edge cases in the YAML writer

## 4.7.0

- feat: remove `json2yaml` dependency, reimplement a simple opinionated YAML writer

## 4.6.1

- fix: automatically initialize the locale when overriding an uninitialized locale (#294)

## 4.6.0

- feat: add `Translations.$copyWith()` and `TranslationMetadata.getOverride` to allow adding custom behavior (#287)
- feat: add Japanese plural resolver (#289)

## 4.5.0

- feat: add `dart run slang configure` to configure `CFBundleLocalizations` in `Info.plist` based on existing translation files
- feat: add `-h / --help / help` command
- feat: add global `generate_enum` config (#283)
- fix: add `unused_element_parameter` to avoid warnings in Dart 3.7 (#282)

## 4.4.1

- fix: also sanitize `of` when used as root key

## 4.4.0

- feat: add `(fallback)` modifier to fallback entries within a map (#268)
- fix: empty strings in base translations should not be removed when using `fallback_strategy: base_locale_empty_string`

## 4.3.0

- feat: simplify file names without namespaces (#267)
- **DEPRECATED:** Do not use namespaces in file names when namespaces are disabled: `strings_de.json` -> `de.json`
- **DEPRECATED:** Always specify the locale in the file name (namespace enabled): `strings.json` -> `strings_en.json`, except the locale is specified in the directory name

Note: This might make the files order in your IDE less pleasant if input and output files are in the same directory.
You can specify the output directory to a subdirectory to avoid this.
For example, `output_directory: lib/i18n/gen`

## 4.2.1

- fix: do not sanitize keys in maps

## 4.2.0

- feat: automatically sanitize invalid keys (e.g. `continue`, `123`) (#257)
- fix: do not override `locale` in L10n format definition

## 4.1.0

- feat: add `format` config to automatically format generated files (#184)
- fix: correctly generate with `enum_name` and `class_name` different from `AppLocale` / `Translations` (#254)

## 4.0.0

**DateFormat, NumberFormat, and Lazy loading**

Format translations with `DateFormat` and `NumberFormat`:

`Hello {name}, today is {today: yMd}. You have {money: currency(symbol: '€')}.`

On web, [Deferred loading](https://dart.dev/language/libraries#lazily-loading-a-library) is used to reduce initial load time.

- feat: add `DateFormat` and `NumberFormat` support (#112)
- feat: add `lazy: true` config which is enabled by default (#135)
- fix: `slang analyze` should not treat translations as unused if they are used in linked translations (#231)
- fix: `slang analyze` should detect missing enums (#234)
- fix: trim enum keys in compressed format while parsing (e.g. `"male, female": "..."` to `"male,female": "..."`) (#247)
- fix: compilation error on web when using large interfaces (#251)
- fix: correctly transform keys with modifiers when `key_case` is set (#253)
- **Breaking:** Require Dart 3.3 and Flutter 3.19
- **Breaking:** `setLocale`, `setLocaleRaw`, and `useDeviceLocale` returns a Future, use `-Sync` suffix for synchronous calls
- **Breaking:** `output_format` removed, always generates multiple files now
- **Breaking:** deprecated functions in `LocaleSettings` (`supportedLocales`, `supportedLocalesRaw`) removed
- **Breaking:** defining contexts (enums) is no longer allowed in `build.yaml` or `slang.yaml` (deprecated in v3.19.0)
- **Breaking:** enums specified in `context` are no longer transformed into pascal case keeping the original case

You can read the detailed migration guide [here](https://github.com/slang-i18n/slang/blob/main/slang/MIGRATION.md).

## 3.32.0

- feat: add syntax to escape linked translations (#248) @Fasust
- i18n: add Polish plural resolver (#245) @0rzech
- docs: broken Unicode CLDR link (#246) @0rzech

## 3.31.2

- fix: should match first language code if there are no matches by country code and at least one match by language code (#241) @Tienisto

## 3.31.1

- fix: "translation overrides" do not work with parameterized linked translations (#226) @Tienisto
- fix: linked translations should not be unused when running `dart run slang analyze` (#222) @Tienisto

## 3.31.0

- feat: add `dart run slang normalize` to normalize translations based on base locale @Tienisto
- feat: add parameter type support (introduced 3.30.0) to ARB files (#214) @Tienisto
- feat: sort translation files for reproducible console output (#210) @poppingmoon

## 3.30.2

- fix: commented out translations should be declared as unused during `slang analyze` (#200) @nikaera
- fix: should use interpolation for strings with a single parameter (#207) @Tienisto
- fix: encode csv files correctly (#202) @nikaera

## 3.30.1

- fix: when applying translations with `dart run slang apply`, only modifiers from the base locale should be used (#192)

## 3.30.0

- feat: add parameter types (e.g. `Hello {name: String}, you are {age: int} years old`); is `Object` by default @Tienisto
- fix: handle nested interfaces (#191) @Tienisto
- refactor: move code to src folder @Tienisto

## 3.29.0

- feat: `dart run slang analyze` supports csv files (#185) @nikaera
- feat: also add linter and coverage ignore to part files (#188) @cmenkemeller
- fix: generate base translations as fallback when using context enums where some enum values are missing (#182) @Tienisto
- fix: generate correct `part of` directive when using a custom dart file extension (#187) @cmenkemeller

## 3.28.0

- feat: add `fallback_strategy: base_locale_empty_string` to also treat empty strings as missing translations (#180)
- fix: special case where linked translations had invalid parenthesis (#181)

## 3.27.0

- feat: add support for ARB files (#179)

## 3.26.2

- fix: should not escape special characters when parsed via the "Translation Overrides" feature (#177)

## 3.26.1

- fix: generate correct compatibility typedef for `Translations` class (#176)

## 3.26.0

- feat: base translation class is named `Translations` so that `Translations.of(context)` returns the same type (#169)
- feat: the name `Translations` can be configured via `class_name` (@bjernie, #174)
- feat: add `statistics` configuration (similar to `timestamp`) to hide statistics in generated file

## 3.25.0

- feat: add `dart run slang clean` to remove unused translations after running `slang analyze` (#141)
- feat: add `--exit-if-changed` to `slang analyze` to fail CI if there are missing / unused translations (#141)
- fix: code generator should not crash if context is not included in i18n (#165)
- fix: should not generate `contextBuilder` and `nBuilder` parameter in rich text if not needed (#168)

## 3.24.0

- feat: `slang edit add` respects order in base locale ([@adil192](https://github.com/adil192))
- feat: `slang edit add` works without a specified locale, it will add the string to all locales
- feat: use `WidgetsBinding.instance.platformDispatcher` instead of `PlatformDispatcher.instance` in `findDeviceLocale` implementation
- fix: correctly obfuscate line breaks and single quotes

## 3.23.0

- feat: support multiple `TranslationProvider` at the same time when using multiple packages
- fix: trailing slash in config does not work with `build_runner`
- i18n: Swedish plural resolver improvement (by [@lohnn](https://github.com/lohnn))

## 3.22.0

- feat: announcing [slang_gpt](https://pub.dev/packages/slang_gpt), a new package to generate translations with GPT

## 3.21.0

- feat: add input directory as comment to generated files
- fix: migrate away from deprecated `WidgetsBinding.instance.window` in `findDeviceLocale` implementation
- fix: handle empty maps in `_missing_translations` in yaml format (by [@adil192](https://github.com/adil192))

## 3.20.0

- feat: add `slang add` to add new translations (by [@adil192](https://github.com/adil192))

## 3.19.0

- feat: add enum value inference (no need to specify `enum` in the config anymore)
- feat: add `slang edit copy` to copy translations
- feat: namespaces may contain underscores if at least one file of same directory uses locale from directory name
- **DEPRECATED:** Use explicit `context` modifier instead of relying on the config file (see [migration guide](https://github.com/slang-i18n/slang/blob/main/slang/MIGRATION.md#use-context-modifier-since-3190))

## 3.18.1

- chore: add logo

## 3.18.0

- feat: add `slang edit` to `move` or `delete` translations over all locales
- fix: avoid infinite loop of symlinks

## 3.17.0

- fix: setLocale does not work when Locale enum is from two packages (by [@fzyzcjy](https://github.com/fzyzcjy))
- fix: `slang outdated` should skip missing translations instead of throwing an error

## 3.16.2

- fix: handle dynamic keys when `fallback_strategy: base_locale` is used

## 3.16.1

- fix: handle interpolation when obfuscation is enabled

## 3.16.0

- feat: add `obfuscation` config to obfuscate translation strings

## 3.15.1

- fix: `slang analyze` with `--full` should find invocations written in multiple lines

## 3.15.0

- feat: add `OUTDATED` modifier to flag translations as outdated (`slang analyze` will treat them as missing)
- feat: run `flutter pub run slang outdated my.key.path` to flag translations as outdated
- feat: `slang apply` prefers modifiers from base locale over secondary locales

## 3.14.0

- feat: `LocaleSettings.useDeviceLocale` listens to device locale changes
- feat: `flutter pub run slang apply` only applies changed locales by default
- fix: locale selection with script code (e.g. `zh-Hant-TW` uses `zh-TW` instead of `zh-HK`)

## 3.13.0

- feat: generated files from `analyze` and `apply` have `\n` at the end of the file

## 3.12.0

- feat: mixins generated by the interface feature now have `==` and `hashCode` overrides
- feat: `flutter pub run slang apply` now respects the order in the base locale instead of simply add the new translations to the end
- feat: `flutter pub run slang analyze` now have `--split-missing` and `--split-unused` (in addition to `--split`) so only one of both can be a single file

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

You can read the detailed migration guide [here](https://github.com/slang-i18n/slang/blob/main/slang/MIGRATION.md).

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

You can read the detailed migration guide [here](https://github.com/slang-i18n/slang/blob/main/slang/MIGRATION.md).
