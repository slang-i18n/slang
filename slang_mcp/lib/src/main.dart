import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';

// ignore: implementation_imports
import 'package:slang/src/builder/builder/slang_file_collection_builder.dart';

// ignore: implementation_imports
import 'package:slang/src/builder/builder/translation_map_builder.dart';

// ignore: implementation_imports
import 'package:slang/src/builder/builder/translation_model_list_builder.dart';

// ignore: implementation_imports
import 'package:slang/src/builder/model/i18n_locale.dart';

// ignore: implementation_imports
import 'package:slang/src/runner/analyze.dart';

// ignore: implementation_imports
import 'package:slang/src/runner/generate.dart';

// ignore: implementation_imports
import 'package:slang/src/runner/wip.dart';
import 'package:slang_mcp/src/tools/add_locale.dart';
import 'package:slang_mcp/src/tools/apply.dart';

const version = '0.1.1';
const notesKey = '@@notes';

void main(List<String> arguments) async {
  if (arguments.isNotEmpty) {
    await _runCli(arguments);
    return;
  }

  final server = McpServer(
    Implementation(
      name: 'slang-mcp-server',
      description:
          'The MCP server for slang, the i18n library for Dart/Flutter.',
      version: version,
    ),
    options: McpServerOptions(
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(),
        resources: ServerCapabilitiesResources(),
        prompts: ServerCapabilitiesPrompts(),
      ),
    ),
  );

  server.registerTool(
    'get-locales',
    description: 'Gets the list of locales in the project',
    callback: (args, extra) async {
      return CallToolResult.fromStructuredContent(await getLocales());
    },
  );

  server.registerTool(
    'get-base-translations',
    description: 'Gets the translations of the base locale.',
    outputSchema: JsonSchema.object(
      description:
          '''A nested map containing the missing translation keys and their corresponding base locale strings.''',
    ),
    callback: (args, extra) async {
      return CallToolResult.fromStructuredContent(await getBaseTranslations());
    },
  );

  server.registerTool(
    'get-missing-translations',
    description:
        'Gets the translations existing in base locale but not in secondary locales.',
    outputSchema: JsonSchema.object(
      description: '''
A map where each key is a locale identifier (e.g., "de", "fr-CA")
and the value is a nested map containing the missing translation keys and their corresponding base locale strings.
The $notesKey entry are just hints and should not be translated''',
    ),
    callback: (args, extra) async {
      return CallToolResult.fromStructuredContent(
          await getMissingTranslationsMap());
    },
  );

  server.registerTool(
    'get-wip-translations',
    description:
        'Gets the translations found in source code (in base locale) that should be translated',
    callback: (args, extra) async {
      return CallToolResult.fromStructuredContent(await getWipTranslations());
    },
  );

  server.registerTool(
    'apply-wip-translations',
    description: '''
Adds the found translations from source code to the actual translation files.
Note: Running apply-translations with **base locale** is not needed afterwards.''',
    callback: (args, extra) async {
      await applyWipTranslations();
      return CallToolResult.fromContent([
        TextContent(text: 'OK'),
      ]);
    },
  );

  server.registerTool(
    'apply-translations',
    description: '''
Adds translations from the provided map to the actual translation files.
Call get-missing-translations first.''',
    inputSchema: ToolInputSchema(
      properties: {
        'locale': JsonSchema.string(
          description: 'Locale identifier (e.g., en, de, fr-CA)',
        ),
        'translations': JsonSchema.object(
          description:
              'A nested map of translation keys and their corresponding translated strings',
        ),
      },
      required: ['locale', 'translations'],
    ),
    callback: (args, extra) async {
      final locale = args['locale'] as String;
      final translations = args['translations'] as Map<String, dynamic>;

      translations.remove(notesKey);

      await apply(
        locale: I18nLocale.fromString(locale),
        translations: translations,
      );

      return CallToolResult.fromContent([
        TextContent(text: 'OK'),
      ]);
    },
  );

  server.registerTool(
    'add-locale',
    description: 'Adds a new locale with translations from the provided map',
    inputSchema: ToolInputSchema(
      properties: {
        'locale': JsonSchema.string(
          description: 'Locale identifier (e.g., en, de, fr-CA)',
        ),
        'translations': JsonSchema.object(
          description:
              'A nested map of translation keys and their corresponding translated strings',
        ),
      },
      required: ['locale', 'translations'],
    ),
    callback: (args, extra) async {
      final locale = args['locale'] as String;
      final translations = args['translations'] as Map<String, dynamic>;

      await addLocale(
        locale: I18nLocale.fromString(locale),
        translations: translations,
      );

      return CallToolResult.fromContent([
        TextContent(text: 'OK'),
      ]);
    },
  );

  await server.connect(StdioServerTransport());

  print('Running slang_mcp!');
}

Future<Map<String, dynamic>> getLocales() async {
  final fileCollection = SlangFileCollectionBuilder.readFromFileSystem(
    verbose: false,
  );
  return {
    'baseLocale': fileCollection.config.baseLocale.languageTag,
    'locales': {
      ...fileCollection.files.map((f) => f.locale.languageTag),
    }.toList(),
  };
}

Future<dynamic> getBaseTranslations() async {
  final fileCollection = SlangFileCollectionBuilder.readFromFileSystem(
    verbose: false,
  );
  final translationMap = await TranslationMapBuilder.build(
    fileCollection: fileCollection,
  );
  final translations = translationMap[fileCollection.config.baseLocale]!;
  return fileCollection.config.namespaces
      ? translations
      : translations.values.first;
}

Future<Map<String, dynamic>> getMissingTranslationsMap() async {
  final fileCollection = SlangFileCollectionBuilder.readFromFileSystem(
    verbose: false,
  );
  final translationMap = await TranslationMapBuilder.build(
    fileCollection: fileCollection,
  );
  final translationModelList = TranslationModelListBuilder.build(
    fileCollection.config,
    translationMap,
  );
  final baseTranslations =
      findBaseTranslations(fileCollection.config, translationModelList);
  final result = getMissingTranslations(
    baseTranslations: baseTranslations,
    translations: translationModelList,
  );

  for (final entry in result.entries) {
    final translations = fileCollection.config.namespaces
        ? translationMap[entry.key]!
        : translationMap[entry.key]!.values.first;

    final notes = translations[notesKey];
    if (notes != null) {
      result[entry.key] = {
        notesKey: notes,
        ...entry.value,
      };
    }
  }

  return {
    for (final entry in result.entries) entry.key.languageTag: entry.value,
  };
}

Future<Map<String, dynamic>> getWipTranslations() async {
  return readWipMapFromFileSystem();
}

Future<void> applyWipTranslations() async {
  await runWip(
    fileCollection: SlangFileCollectionBuilder.readFromFileSystem(
      verbose: false,
    ),
    arguments: ['apply'],
  );

  // Generate after applying with new translations
  await generateTranslations(
    fileCollection: SlangFileCollectionBuilder.readFromFileSystem(
      verbose: false,
    ),
  );
}

Future<void> _runCli(List<String> arguments) async {
  final encoder = JsonEncoder.withIndent('  ');
  final Map<String, Future<String?> Function()> commands = {
    '--version': () async {
      return version;
    },
    'get-locales': () async {
      return encoder.convert(await getLocales());
    },
    'get-base-translations': () async {
      return encoder.convert(await getBaseTranslations());
    },
    'get-missing-translations': () async {
      return encoder.convert(await getMissingTranslationsMap());
    },
    'get-wip-translations': () async {
      return encoder.convert(await getWipTranslations());
    },
    'apply-wip-translations': () async {
      await applyWipTranslations();
      return null;
    },
  };

  final command = arguments[0];
  final fn = commands[command];
  if (fn == null) {
    print('Unknown command: $command');
    print('Available commands: ${commands.keys.join(', ')}');
    return;
  }

  final output = await fn();
  if (output != null) {
    print('');
    print(output);
    print('');
  }
  print('Command "$command" executed successfully.');
}
