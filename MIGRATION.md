# Migration Guides

## Version 5.0

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