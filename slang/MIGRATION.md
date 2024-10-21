# Migration Guides

## slang 3.0 to 4.0

### Lazy Loading

The 4.0 release expects the translations to be loaded asynchronously by default.
This makes it easy to support lazy loading of translations on Web.

If you don't want to load translations asynchronously, you can set `lazy: false` in the `slang.yaml` or `build.yaml`.
Then, you are able to call `LocaleSettings.setLocaleSync`, `LocaleSettings.setLocaleRawSync` (and other sync methods) without any issues.

### Context Type conversion

Previously, context types are converted to pascal case. This is no longer the case.

```yaml
contexts:
  gender_context: # Previously, converted to GenderContext
    default_parameter: gender
```

Now, you should use the exact context type.

```yaml
contexts:
  GenderContext:
    default_parameter: gender
```

## Use context modifier (since 3.19.0)

Since 3.19, slang supports context enum inference (i.e. you don't need to specify the exact enum values in the config).

Auto detection of contexts are prone to side effects. It is recommended to add an explicit `context` modifier instead:

Before

```json5
{
  "greet": {
    "male": "Hello Mr $name",
    "female": "Hello Ms $name"
  }
}
```

```yaml
# Config
contexts:
  GenderContext:
    enum:
      - male
      - female
  UserType:
    enum:
      - user
      - admin
```

After

```json5
{
  "greet(context=GenderContext)": {
    "male": "Hello Mr $name",
    "female": "Hello Ms $name"
  }
}
```

```yaml
# no config needed
```

## slang 2.0 to 3.0

1. Update plural parameter to `n`.

```json5
{
  "apple": {
    "one": "I have $n apple.",
    "other": "I have $n apples."
  }
}
```

Alternative:

```yaml
# Config
pluralization:
  default_parameter: count # revert it back to "count"
```

2. Update custom plural / context parameter. Custom parameter names now have a prefix `param=`.

```json5
{
  "apple(param=appleCount)": {
    "one": "I have one apple.",
    "other": "I have $appleCount apples."
  }
}
```

Additional info: There are now `(map)`, `(plural)`, `(cardinal)` and a lot more modifiers.

## fast_i18n to slang

### Update dependencies

```yaml
dependencies:
  slang: <version>
  slang_flutter: <version> # also add this if you use flutter

dev_dependencies:
  build_runner: <version> # if you use build_runner (1/2)
  slang_build_runner: <version> # if you use build_runner (2/2)
  # fast_i18n: 5.12.3 (removed)
```

### Update build.yaml

Rename builder name to `slang_build_runner`.

Deprecated `output_file_pattern` removed.

`output_file_name` defaulting to `strings.g.dart`.

```yaml
# build.yaml
targets:
  $default:
    builders:
      slang_build_runner: # rename from fast_i18n to slang_build_runner
        options:
          # output_file_pattern: .g.dart (removed)
          output_file_name: strings.g.dart # new default
```

Or make use of the new `slang.yaml` (works without `build_runner`):
```yaml
# slang.yaml
base_locale: en
translate_var: t
```

### Command

If you generate via `dart run fast_i18n`, please make sure to call `slang` instead.

`dart run slang`

## fast_i18n 4.0 to 5.0

This release mostly focuses on simplifications of `build.yaml`.

### Builder Name

Simplify `fast_i18n:i18nBuilder` to `fast_i18n`.

```yaml
targets:
  $default:
    builders:
      fast_i18n: # no more "fast_i18n:i18nBuilder"
        options:
          base_locale: fr
```

### Plural Auto Detection

Setting `auto: cardinal` by default applies to most projects. This means that you don't need the `pluralization` section at all in your `build.yaml`!

```yaml
targets:
  $default:
    builders:
      fast_i18n:
        options:
          pluralization:
            auto: cardinal # default
```

### Fallback Strategy

The previous default mode `strict` has been renamed to `none`, This makes more sense because there is no fallback strategy at all.

```yaml
targets:
  $default:
    builders:
      fast_i18n:
        options:
          fallback_strategy: none # was "strict"
```

### Paths & Key Case

Only for developers using both `key_case` and any path related feature (`maps`, `pluralization` paths, `context` paths).

Paths must be cased according to `key_case` if specified.

```json
 {
  "a_b": {
    "hi": "hi"
  }
}
```

```yaml
targets:
  $default:
    builders:
      fast_i18n:
        options:
          key_case: camel # this forces every other path also be in camel case
          maps:
            - aB
```

### Null Safety

Null safety is must have. This will simplify the library code base.

### Linked Translations

Messages containing `@:` are interpreted as linked translations from now on. In edge cases this may break.

```json
{
  "meta": {
    "appName": "My App"
  },
  "welcome": "Welcome to @:meta.appName"
}
```