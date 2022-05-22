# Contributing

## Pipeline

### 1 BuildConfig

Read `slang.yaml` or `build.yaml` to build the `BuildConfig` object.

### 2 List of TranslationFile

Detect all potential translation files and build `List<TranslationFile>`.

Each `TranslationFile` is just a reference to a file. We do not read its content for now.

### 3 TranslationMap

Read all files of step 2 and build the `TranslationMap` object.

Now we have all locales, its namespaces and its translations represented as pure maps.

### 4 BuildResult

The `GeneratorFacade` class will read the translation maps from previous step and generates the resulting file content.

## Integration Test

In case of making changes to the resulting `.g.dart` file, integration tests may fail.

You can update the integration tests via this command:

```text
cd slang
dart test/integration/update.dart
```
