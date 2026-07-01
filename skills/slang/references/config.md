# Slang Configuration — Complete Reference

Every option available in `slang.yaml` or under `slang_build_runner.options` in
`build.yaml`. Values shown are defaults unless marked "No default."

## Locale & Fallback

| Option              | Type                                                | Default | Description                                                                                                                                                                                                |
| ------------------- | --------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `base_locale`       | `String`                                            | `en`    | Locale of the primary/authoritative JSON file. All other locales fall back to this one (depending on `fallback_strategy`).                                                                                 |
| `fallback_strategy` | `none` / `base_locale` / `base_locale_empty_string` | `none`  | `none` — missing keys throw at runtime. `base_locale` — missing keys resolve to the base locale value. `base_locale_empty_string` — missing keys resolve to empty string instead of the base locale value. |

## Input & Output

| Option               | Type     | Default      | Description                                                                                           |
| -------------------- | -------- | ------------ | ----------------------------------------------------------------------------------------------------- |
| `input_directory`    | `String` | No default   | Directory containing `.i18n.json` files. Must be set explicitly. Common: `lib/i18n` or `assets/i18n`. |
| `input_file_pattern` | `String` | `.i18n.json` | File pattern for input files. Must end with `.json`, `.yaml`, `.csv`, or `.arb`.                      |
| `output_directory`   | `String` | No default   | Directory for the generated Dart file. Usually matches `input_directory`.                             |
| `output_file_name`   | `String` | No default   | Name of the generated file. Common: `strings.g.dart` or `translations.g.dart`. Must end with `.dart`. |

## Code Generation

| Option                         | Type                 | Default        | Description                                                                                                                                                                    |
| ------------------------------ | -------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `translate_var`                | `String`             | `t`            | Name of the global translation accessor variable. Standard is `t`, giving `t.path.to.key`.                                                                                     |
| `enum_name`                    | `String`             | `AppLocale`    | Name of the generated locale enum. Contains one entry per locale (e.g., `AppLocale.ptBr`).                                                                                     |
| `class_name`                   | `String`             | `Translations` | Name of the generated translations class.                                                                                                                                      |
| `translation_class_visibility` | `private` / `public` | `private`      | `private` — class generated with `_` prefix, only accessible via the `t` variable. `public` — class is public (use for DI/Riverpod).                                           |
| `locale_handling`              | `Boolean`            | `true`         | When `true`, generates `LocaleSettings`, `LocaleSettings.useDeviceLocale()`, `TranslationProvider`, and `AppLocaleUtils`. Set to `false` when using full dependency injection. |
| `flutter_integration`          | `Boolean`            | `true`         | When `true`, generates Flutter-specific helpers (`TranslationProvider`, `flutterLocale` extension). Set to `false` for pure Dart projects.                                     |
| `lazy`                         | `Boolean`            | `true`         | Load locale data on first access rather than at startup. Better for startup performance.                                                                                       |
| `timestamp`                    | `Boolean`            | `true`         | Stamp "Built on <date>" at the top of the generated file. Set to `false` to avoid noisy git diffs.                                                                             |
| `statistics`                   | `Boolean`            | `true`         | Write locale and string count statistics as a comment in the generated file.                                                                                                   |
| `generate_enum`                | `Boolean`            | `true`         | Global toggle for enum generation in contexts. Override per-context with `contexts.<Name>.generate_enum`.                                                                      |

## Namespacing

| Option                        | Type           | Default | Description                                                                                                                                        |
| ----------------------------- | -------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `namespaces`                  | `Boolean`      | `false` | When `true`, splits translations into multiple files per locale. File naming: `<namespace>_<locale>.i18n.json`. Access: `t.namespace.path.to.key`. |
| `translate_var_per_namespace` | `Boolean`      | `false` | When `true`, creates a `t` variable per namespace.                                                                                                 |
| `namespace_globs`             | `List<String>` | `[]`    | Glob patterns for namespace file discovery.                                                                                                        |

## Key & Param Casing

| Option         | Type                                  | Default | Description                                                                                         |
| -------------- | ------------------------------------- | ------- | --------------------------------------------------------------------------------------------------- |
| `key_case`     | `null` / `camel` / `pascal` / `snake` | `null`  | Transforms JSON keys in generated code. `null` — keys used as-is. `camel` — `app_name` → `appName`. |
| `key_map_case` | `null` / `camel` / `pascal` / `snake` | `null`  | Transforms keys for map-typed entries in generated code.                                            |
| `param_case`   | `null` / `camel` / `pascal` / `snake` | `null`  | Transforms parameter names in generated code.                                                       |

## String Interpolation

| Option                 | Type                                | Default | Description                                                                     |
| ---------------------- | ----------------------------------- | ------- | ------------------------------------------------------------------------------- |
| `string_interpolation` | `dart` / `braces` / `double_braces` | `dart`  | `dart` — `$name`, `${name}`. `braces` — `{name}`. `double_braces` — `{{name}}`. |

## Advanced Features

### Pluralization

| Option                            | Type                           | Default    | Description                                                                                    |
| --------------------------------- | ------------------------------ | ---------- | ---------------------------------------------------------------------------------------------- |
| `pluralization.auto`              | `off` / `cardinal` / `ordinal` | `cardinal` | Auto-detect plural forms from JSON keys (`one`, `other`, etc.). `off` disables auto-detection. |
| `pluralization.default_parameter` | `String`                       | `n`        | Default parameter name for plural forms.                                                       |
| `pluralization.cardinal`          | `List<String>`                 | `[]`       | Explicit list of cardinal plural entries (e.g., `someKey.apple`).                              |
| `pluralization.ordinal`           | `List<String>`                 | `[]`       | Explicit list of ordinal plural entries (e.g., `someKey.place`).                               |

### Contexts (Enums)

| Option                              | Type      | Default   | Description                                                                        |
| ----------------------------------- | --------- | --------- | ---------------------------------------------------------------------------------- |
| `contexts.<Name>.default_parameter` | `String`  | `context` | Default parameter name for this context (e.g., `gender`).                          |
| `contexts.<Name>.generate_enum`     | `Boolean` | `true`    | Generate an enum for this context. Set to `false` when importing an existing enum. |

### Interfaces

| Option                             | Type           | Default | Description                                                                                                                |
| ---------------------------------- | -------------- | ------- | -------------------------------------------------------------------------------------------------------------------------- |
| `interfaces.<Name>.generate_mixin` | `Boolean`      | `true`  | Generate a mixin for this interface.                                                                                       |
| `interfaces.<Name>.attributes`     | `List<String>` | `null`  | Explicit attribute definitions (e.g., `String title`, `String? content`). When `null`, attributes are inferred from usage. |

### Maps & Flat Map

| Option                  | Type           | Default | Description                                                                                              |
| ----------------------- | -------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| `maps`                  | `List<String>` | `[]`    | Entries to treat as dynamic-key maps (e.g., `error.codes`). Equivalent to the `(map)` modifier in JSON.  |
| `flat_map`              | `Boolean`      | `true`  | Generate a flat `t['path.to.key']` accessor for dynamic key access.                                      |
| `translation_overrides` | `Boolean`      | `false` | Enable `LocaleSettings.overrideTranslations()` for runtime translation overrides (e.g., from a backend). |

### Sanitization

| Option                 | Type                                  | Default | Description                                                                   |
| ---------------------- | ------------------------------------- | ------- | ----------------------------------------------------------------------------- |
| `sanitization.enabled` | `Boolean`                             | `true`  | Sanitize generated names that conflict with Dart keywords by adding a prefix. |
| `sanitization.prefix`  | `String`                              | `k`     | Prefix added to sanitized names.                                              |
| `sanitization.case`    | `null` / `camel` / `pascal` / `snake` | `camel` | Case style for sanitized names.                                               |

### Obfuscation

| Option                | Type      | Default | Description                                          |
| --------------------- | --------- | ------- | ---------------------------------------------------- |
| `obfuscation.enabled` | `Boolean` | `false` | Obfuscate translation strings in the generated code. |
| `obfuscation.secret`  | `String`  | random  | Secret key for obfuscation. Random if not set.       |

### Formatting

| Option           | Type      | Default | Description                                                           |
| ---------------- | --------- | ------- | --------------------------------------------------------------------- |
| `format.enabled` | `Boolean` | `false` | Auto-format the generated Dart file.                                  |
| `format.width`   | `int`     | `null`  | Line width for auto-formatting. Uses `dart format` default if `null`. |

### Autodoc

| Option            | Type           | Default  | Description                                                                              |
| ----------------- | -------------- | -------- | ---------------------------------------------------------------------------------------- |
| `autodoc.enabled` | `Boolean`      | `true`   | Generate documentation comments from translations.                                       |
| `autodoc.locales` | `List<String>` | `$BASE$` | List of locale codes to generate documentation for. `$BASE$` means the base locale only. |

### Imports

| Option    | Type           | Default | Description                                                                                            |
| --------- | -------------- | ------- | ------------------------------------------------------------------------------------------------------ |
| `imports` | `List<String>` | `[]`    | Additional import statements to include in the generated file. Use for external enums (package paths). |

## Common Configurations

### Minimal Flutter App

```yaml
base_locale: en
fallback_strategy: base_locale
input_directory: lib/i18n
input_file_pattern: .i18n.json
output_directory: lib/i18n
output_file_name: strings.g.dart
```

### Production Flutter App (Recommended)

```yaml
base_locale: en
fallback_strategy: base_locale
input_directory: lib/i18n
input_file_pattern: .i18n.json
output_directory: lib/i18n
output_file_name: strings.g.dart
translate_var: t
enum_name: AppLocale
class_name: Translations
lazy: true
locale_handling: true
flutter_integration: true
namespaces: false
string_interpolation: dart
flat_map: true
timestamp: false
statistics: true
```

### Pure Dart (No Flutter)

```yaml
base_locale: en
fallback_strategy: base_locale
input_directory: lib/i18n
output_directory: lib/i18n
output_file_name: strings.g.dart
flutter_integration: false
locale_handling: true
```

### Riverpod DI Integration

```yaml
base_locale: en
fallback_strategy: base_locale
input_directory: lib/i18n
output_directory: lib/i18n
output_file_name: strings.g.dart
locale_handling: false
translation_class_visibility: public
```

Then create a Riverpod provider:

```dart
final translationsProvider = StateProvider<Translations>(
  (ref) => AppLocale.en.buildSync(),
);
```

### Translation-Platform-Friendly (double_braces interpolation, public class)

```yaml
base_locale: en
string_interpolation: double_braces
translation_class_visibility: public
```
