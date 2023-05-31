# Contributing

## Generator Pipeline

### 1 SlangFileCollection

Build a collection of translation files by (a) reading the file system or (b) reading the build_runner inputs.

The collection also includes the `slang.yaml` or `build.yaml` config.

Every file is represented as `TranslationFile` object. This object contains the file path and the abstracted read operation.

After this step, we have a common model that can be used by the custom runner and by build_runner.

### 2 TranslationMap

Build a map containing content of all translation files.

We use the `TranslationFile` objects from step 1 to read the file content and build a map of all translation strings.

After this step,

(1) The path and file type information is lost.

(2) We only have the locale, namespace and translation strings.

### 3 BuildResult

The `GeneratorFacade` class will read the translation maps from previous step and generates the resulting file content.

## Integration Test

In case of making changes to the resulting `.g.dart` file, integration tests may fail.

You can update the integration tests via this command:

```text
cd slang
dart test/integration/update.dart
```
