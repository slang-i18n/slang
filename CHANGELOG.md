## 3.0.1-dev.0

- add real project example
- update FAQ in README
- depend on null-safety version of recase package

## 3.0.0

- null safety support
- add type-safe functions `LocaleSettings.setLocaleTyped` and `LocaleSettings.currentLocaleTyped`
- **Breaking:** `output_translate_var` renamed to `translate_var` in `build.yaml`

## 2.3.1

- Make locales case sensitive to comply with `MaterialApp`'s `supportedLocales`.

## 2.3.0

- Add `supportedLocales` property that can be used to fill `MaterialApp`'s `supportedLocales` argument.

## 2.2.1

- Fix compilation error occurring when non-standard name (not 'strings.i18n.json') is used for json files.

## 2.2.0

- new config: `output_translate_var`, renames default `t` variable
- internal: device locale now fetched via `Platform.localeName`

## 2.1.0

A rebuild is needed: `flutter pub run build_runner build`.

- API change: LocaleSettings.useDeviceLocale() is no longer asynchronous and now returns the new locale (was `Future<void>`)
- API change: LocaleSettings.setLocale(locale) now also returns the new locale (was `void`)

Just in case you use internal API:
FastI18n.findDeviceLocale has been renamed to FastI18n.getDeviceLocale

## 2.0.0

Thanks to @DenchikBY (https://github.com/DenchikBY).

- Now it's possible to set in and out directories for files.
- You can set the pattern by which to search for files.
- Generated keys can be switched to another case in generated classes.
- Removed dependency on devicelocale.
- Configs with baseLocale and maps moved from config.i18n.json to build.yaml
- Generators replaced with fields for keys with static values.
- Arguments now can be wrapped with braces like ${key}.
- Removed deprecated `#map` mode (deprecated in 1.5.0)

Example of new config in build.yaml:
```yaml
targets:
  $default:
    builders:
      fast_i18n:i18nBuilder:
        options:
          base_locale: en
          input_directory: lib/i18n
          input_file_pattern: .i18n.json
          output_directory: lib/i18n
          output_file_pattern: .g.dart
          key_case: snake
          maps:
            - a
            - b
            - c.d
```

## 1.8.2

- Hotfix: possible NPE when calling Translations.of(context)

## 1.8.1

- Hotfix: possible NPE error when calling LocaleSettings.useDeviceLocale or LocaleSettings.setLocale

## 1.8.0

- New advanced mode: final t = Translations.of(context)

## 1.7.0

- Prefer language code over region code.

## 1.6.1

- Add more unit tests.
- Code Polishing.

## 1.6.0

- Generates `List<String>` or `Map<String, String>` instead of `List<dynamic>` or `Map<String, dynamic>` if the children are only strings.
- You will experience a better autocompletion like `.substring`, `.indexOf`, etc. because of that.

## 1.5.0+2

- Update README

## 1.5.0+1

- Update README

## 1.5.0

- Define additional metadata in the `config.i18n.json` file.

- Maps defined with `#map` are now deprecated. Use `config.i18n.json` for that.

- Add `LocaleSettings.locales` to get the supported locales.

## 1.4.0

- Add support for country codes. Use e.g. `strings_en_US.i18n.json` or `strings_en-US.i18n.json`.

- Add fallback for `LocaleSettings.setLocale` if locale is not supported.

## 1.3.0

- Add support for lists.

- Add support for maps. Use `{ "#map": "" }` to enable map inlining.

## 1.2.0+1

- Update README

## 1.2.0

- Only one single `.g.dart` will be generated

## 1.1.2

- Fix iOS bug in `LocaleSettings.useDeviceLocale`

## 1.1.1

- Fix for `LocaleSettings.useDeviceLocale`

## 1.1.0

- Add `LocaleSettings.useDeviceLocale()`

## 1.0.0

- Initial Release
- basic json support (no arrays)
