# slang_mcp

The [MCP](https://modelcontextprotocol.io) server for [slang](https://pub.dev/packages/slang).

Use LLMs to automatically translate your app at compile time.

Exposes an API for LLMs to find missing translations, WIP translations,
and allows LLMs to add new translations without requiring knowledge about folder structure, file formats, etc.

This MCP server adds around 540 tokens into the context (which is 0.27% of 200k tokens in Claude).

## Motivation

LLMs are increasingly being used to help with translation tasks.
However, letting LLMs directly access translation files can be slow, feedback intensive,
and error-prone.

Compared to [slang_gpt](https://pub.dev/packages/slang_gpt),
the MCP approach offers a more standardized and extensible way to interact with translation data.

In particular, this package does not need knowledge about API keys
which is necessary to work with Claude Code or other subscriptions.

## Advantages

### ➤ Over direct file access

- **Token Efficiency**: MCP allows LLMs to request only the data they need,
  reducing the amount of text that needs to be processed.
- **Speed**: LLMs don't need to find what files are relevant, MCP handles that - reducing unnecessary file reads.
- **Robustness**: LLMs are only responsible for generating translations, nothing more.

### ➤ Over slang_gpt

- **LLM agnostic**: Works with any LLM that supports MCP.
- **No API key**: No need to manage API keys. Works with LLM subscriptions that do not provide API access (e.g. Claude Code).

## Installation

Install the package globally:

```bash
dart pub global activate slang_mcp
```

Register the MCP server in your LLM tooling.

Note: The working directory should be your Flutter app
where the `build.yaml` / `slang.yaml` file is located.

```bash
# Claude Code
cd my_flutter_app/
claude mcp add --transport stdio slang_mcp -- slang_mcp
```

## MCP API

| Tool                       | Input                    | Description                                                                               |
|----------------------------|--------------------------|-------------------------------------------------------------------------------------------|
| `get-locales`              | -                        | Gets the list of locales in the project                                                   |
| `get-base-translations`    | -                        | Gets the translations of the base locale                                                  |
| `get-missing-translations` | -                        | Gets translations that exist in the base locale but not in secondary locales              |
| `get-wip-translations`     | -                        | Gets WIP translations found in source code that should be translated                      |
| `apply-wip-translations`   | -                        | Applies WIP translations from source code to translation files and regenerates the output |
| `apply-translations`       | `locale`, `translations` | Adds translations to the actual translation files and regenerates the output              |
| `add-locale`               | `locale`, `translations` | Adds a new locale with translations and regenerates the output                            |


## Notes

You can add `@@notes` to a translation file to provide context to the LLM.
This is useful to inform the LLM about the language, tone, or other details relevant to the translation.

The notes are automatically included when calling `get-missing-translations`.
It can be any JSON-serializable value.

```json
{
  "@@notes": {
    "general": [
      "The app is a banking app, so use financial terms.",
      "The tone should be formal and professional."
    ],
    "dictionary": {
      "bank": "Bank (financial institution, not 'Ufer')"
    }
  },
  "welcome": "Willkommen"
}
```

## Workflows

### ➤ Translate missing translations

This requires `fallback_strategy: base_locale`.

Prompt the LLM:

```text
Translate the missing translations
```

### ➤ Add new locale

Prompt the LLM:

```text
Translate the app to Spanish (es)
```

### ➤ Apply and translate WIP translations

This makes use of slang's [WIP](https://pub.dev/packages/slang#-prototyping) feature for quick development.

It allows you to work on new features in your Dart files
without having to touch translation files
or waiting for code generation.

Step 1: Prototype your new feature.

```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () {},
            child: Text(context.t.$wip.loginPage.loginButton('Login')),
          ),
          TextButton(
            onPressed: () {},
            child: Text(context.t.$wip.loginPage.forgotPasswordButton('Forgot Password')),
          ),
        ],
      ),
    );
  }
}
```

Step 2: Prompt the LLM

```text
Apply my new WIP strings and translate
```

The MCP server should receive the translated strings and apply them to the appropriate files.

## Install from source

Clone the repository and navigate to the project directory.

Then install the package globally:

```bash
dart pub global activate --source path .
```
