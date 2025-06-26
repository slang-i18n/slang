# slang_openai

Use Use any OpenAI compatible API to automatically translate your app at compile time.

This is library is intended to be used with [slang](https://pub.dev/packages/slang).

## Motivation

Google Translate and other translation services are great, but they are not perfect.

One of the biggest issues is that they are not context aware. For example, the word "bank" can be translated to "Bank" or "Ufer" in German depending on the context.

With LLMs and some prompt engineering, we can get context aware translations.

## Getting Started

```yaml
# pubspec.yaml
dependencies:
  slang: <version>

dev_dependencies:
  slang_openai: <version>
```

Add the `openai` entry to `build.yaml` or `slang.yaml`.

```yaml
# existing config
base_locale: fr
fallback_strategy: base_locale
input_directory: lib/i18n
input_file_pattern: .i18n.json
output_directory: lib/i18n

# add this
openai:
  model: gpt-4
  description: |
    "River Adventure" is a game where you need to cross a river by jumping on stones.
    The game is over when you either fall into the water or reach the other side.
```

Let's run this:

```bash
dart run slang_openai --target=fr --api-key=<api-key>
```

## Configuration

| Key                | Type     | Usage                            | Required | Default                            |
|--------------------|----------|----------------------------------|----------|------------------------------------|
| `url`              | `String` | The base URL for the OpenAI API  | NO       | api.openai.com/v1/chat/completions |
| `model`            | `String` | Model name                       | YES      |                                    |
| `max_input_length` | `int`    | Max input characters per request | NO       | 10.000                             |
| `temperature`      | `double` | Temperature parameter for LLM    | NO       | (API default)                      |
| `description`      | `String` | App description                  | YES      |                                    |
| `excludes`         | `List`   | List of locales to exclude       | NO       | `[]`                               |

## Command line arguments

| Argument         | Description              | Required | Default                | Options                    |
|------------------|--------------------------|----------|------------------------| ---------------------------|
| `--provider=`    | Provider preset          | NO       |                        | openai, openrouter, ollama |
| `--target=`      | Target language          | NO       | (all existing locales) |                            |
| `--api-key=`     | API key                  | NO*      |                        |                            |
| `-f` / `--full`  | Skip partial translation | NO       | (partial translation)  |                            |
| `-d` / `--debug` | Write chat to file       | NO       | (no chat output)       |                            |
| `--outdir=`      | Output directory         | NO*      | (using config)         |                            |

## LLMs context length

Each model has a different context length. Try to avoid exceeding it as the model starts to "forget".

Luckily, slang_openai supports splitting the input into multiple requests.

The `max_input_length` is optional and defaults to 10k.

If you work with less common languages and the model starts to forget, try to reduce the `max_input_length`.

Alternatively, you can also use a model with a larger context length.

## Partial translation

By default, slang_openai will only translate missing keys to reduce costs.

You may add the `--full` flag to translate all keys.

```bash
dart run slang_openai --target=fr --full --api-key=<api-key>
```

To avoid a specific subset of keys from being translated, you may add the `ignoreOpenai` modifier to the key:

```json
{
  "key1": "This will be translated",
  "key2(ignoreOpenai)": {
    "key3": "This will be ignored"
  }
}
```

## Target language

By default, slang_openai will translate to all existing locales.

You may add the `--target` flag to translate to a specific locale. This may be useful if you want to translate to a new locale.

Additionally, you may also use predefined language sets (keep in mind that English must be the base locale):

**By GDP (Gross Domestic Product):**

| Flag              | Languages                                                           |
|-------------------|---------------------------------------------------------------------|
| `--target=gdp-3`  | `["zh-Hans", "es", "ja"]`                                           |
| `--target=gdp-5`  | `["zh-Hans", "es", "ja", "de", "fr"]`                               |
| `--target=gdp-10` | `["zh-Hans", "es", "ja", "de", "fr", "pt", "ar", "it", "ru", "ko"]` |

**By region and population:**

| Flag             | Languages                                                      |
|------------------|----------------------------------------------------------------|
| `--target=eu-3`  | `["de", "fr", "it"]`                                           |
| `--target=eu-5`  | `["de", "fr", "it", "es", "pl"]`                               |
| `--target=eu-10` | `["de", "fr", "it", "es", "pl", "ro", "nl", "cs", "el", "sv"]` |
