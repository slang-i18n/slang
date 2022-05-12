# slang_build_runner

`build_runner` support for [slang](https://pub.dev/packages/slang).

Using `slang` alone, you can already run `flutter pub run slang` but sometimes you want to use multiple source generators.

In Flutter, `build_runner` is the standard solution. This library ensures that `build_runner` recognizes `slang` without having `build` as transitive dependency.

```yaml
dependencies:
  slang: <version>

dev_dependencies:
  build_runner: <version>
  slang_build_runner: <version>
```
