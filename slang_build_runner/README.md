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
flutter pub run build_runner build --delete-conflicting-outputs
```