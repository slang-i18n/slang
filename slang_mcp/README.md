# slang_mcp

An [MCP](https://modelcontextprotocol.io) server for [slang](https://pub.dev/packages/slang).

Exposes an API for LLMs to find missing translations, WIP translations,
and allows LLMs to add new translations without requiring knowledge about folder structure, file formats, etc.

## Motivation

LLMs are increasingly being used to help with translation tasks.
However, letting LLMs directly access translation files can be error-prone and insecure.

Compared to [slang_gpt](https://pub.dev/packages/slang_gpt),
the MCP approach offers a more standardized and extensible way to interact with translation data.

In particular, this package does not need knowledge about API keys
which is necessary to work with Claude Code or other subscriptions.

## Advantages over direct file access

- **Token Efficiency**: MCP allows LLMs to request only the data they need,
  reducing the amount of text that needs to be processed.
- **Speed**: LLMs don't need to find what files are relevant, MCP handles that - reducing unnecessary file reads.
- **Robustness**: LLMs are only responsible for generating translations, not more.

## Installation

Install the package globally:

```bash
dart pub global activate slang_mcp
```

Register the MCP server in your LLM tooling:

```bash
# Claude Code
claude mcp add slang_mcp slang_mcp
```

## Workflows

### ➤ Translate missing translations

This requires `fallback_strategy: base_locale`.

Prompt the LLM:

```
Translate the missing translations
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

```
Apply my new WIP strings and translate
```

The MCP server should receive the translated strings and apply them to the appropriate files.
