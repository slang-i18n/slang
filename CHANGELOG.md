## [1.6.0]

Generates `List<String>` or `Map<String, String>` instead of `List<dynamic>` or `Map<String, dynamic>` if the children are only strings.

You will experience a better autocompletion like `.substring`, `.indexOf`, etc. because of that.

## [1.5.0+2]

Update README

## [1.5.0+1]

Update README

## [1.5.0]

Define additional metadata in the `config.i18n.json` file.

Maps defined with `#map` are now deprecated. Use `config.i18n.json` for that.

Add `LocaleSettings.locales` to get the supported locales.

## [1.4.0]

Add support for country codes. Use e.g. `strings_en_US.i18n.json` or `strings_en-US.i18n.json`.

Add fallback for `LocaleSettings.setLocale` if locale is not supported.

## [1.3.0]

Add support for lists.

Add support for maps. Use `{ "#map": "" }` to enable map inlining.

## [1.2.0+1]

Update README

## [1.2.0]

Only one single `.g.dart` will be generated

## [1.1.2]

Fix iOS bug in `LocaleSettings.useDeviceLocale`

## [1.1.1]

Fix for `LocaleSettings.useDeviceLocale`

## [1.1.0]

Add `LocaleSettings.useDeviceLocale()`

## [1.0.0]

Initial Release
- basic json support (no arrays)
