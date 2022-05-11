# Migration Guides

## fast_i18n 5.0 to slang 1.0

### Update dependencies

```yaml
dependencies:
  slang: 1.0.0 # add this
  slang_flutter: 1.0.0 # also add this if you use flutter

dev_dependencies:
  build_runner: any # only needed if you use build_runner command
  # fast_i18n: 5.12.3 (removed)
```

### Update build.yaml

Deprecated `output_file_pattern` removed. `output_file_name` defaulting to `strings.g.dart`.

```yaml
targets:
  $default:
    builders:
      slang: # rename from fast_i18n to slang
        options:
          # output_file_pattern: .g.dart (removed)
          output_file_name: strings.g.dart # new default
```

### Command

If you generate via `flutter pub run fast_i18n`, please make sure to call `slang` instead.

`flutter pub run slang`

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