# slang_build_runner

`build_runner` support for [slang](https://pub.dev/packages/slang).

Useful if you want to combine multiple code generators.

This library ensures that `slang` is recognized by `build_runner`.

```yaml
# pubspec.yaml
dependencies:
  slang: <version>

dev_dependencies:
  build_runner: <version>
  slang_build_runner: <version>
```

Make sure to use `build.yaml` instead of `slang.yaml`.

```yaml
# build.yaml
targets:
  $default:
    builders:
      slang_build_runner:
        options:
          base_locale: en
```

The generate command:

```text
dart run build_runner build --delete-conflicting-outputs
```

## Legacy builder

Some users reported problems (e.g. `Asset already exists`)
with the new builder that uses build_runner's asset writer.

- https://github.com/slang-i18n/slang/issues/351
- https://github.com/dart-lang/build/issues/4402
- https://github.com/dart-lang/build/issues/4975

If you need the old behavior where the files are written directly to disk via `dart:io`,
you can opt into the `legacy` builder.

Note: It does not support `build_runner build --workspace`.

Disable the default builder and enable the legacy one:

```yaml
# build.yaml
targets:
  $default:
    builders:
      slang_build_runner:
        enabled: false
      slang_build_runner:legacy:
        enabled: true
        options:
          base_locale: en
```
