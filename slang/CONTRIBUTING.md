# Contributing

## Pipeline

### 1 BuildConfig

Read `slang.yaml` or `build.yaml` to build the `BuildConfig` object.

### 2 List of TranslationFile

Detect all potential translation files and build `List<TranslationFile>`.

### 3 TranslationMap

Read all files of the `TranslationFileCollection` and build the `TranslationMap` object.

Now we have all locales, its namespaces and its translations represented as pure maps.

### 4 BuildResult

The `GeneratorFacade` class will read the translation maps from previous step and generates the resulting file content.
