# slang_build_runner

`build_runner` support for [slang](https://pub.dev/packages/slang).

Using `slang` alone, you can already run `flutter pub run slang` but sometimes you want to combine multiple source generators.

This library ensures that `build_runner` recognizes `slang` without having `build` as transitive dependency.

```yaml
dependencies:
  slang: <version>

dev_dependencies:
  build_runner: <version>
  slang_build_runner: <version>
```

The `build.yaml` file should be already in the correct format.

```yaml
targets:
  $default:
    builders:
      slang:
        options:
          base_locale: en
          # other options
```

The generate command:

```text
flutter pub run build_runner build --delete-conflicting-outputs
```