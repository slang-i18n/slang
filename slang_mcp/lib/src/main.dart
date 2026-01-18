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
import 'package:slang/src/runner/apply.dart';

// ignore: implementation_imports
import 'package:slang/src/runner/generate.dart';

// ignore: implementation_imports
import 'package:slang/src/runner/wip.dart';

void main(List<String> arguments) async {
  final server = McpServer(
    Implementation(
      name: 'slang-mcp-server',
      version: '0.1.0',
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
      final fileCollection = SlangFileCollectionBuilder.readFromFileSystem(
        verbose: false,
      );
      return CallToolResult.fromStructuredContent({
        'baseLocale': fileCollection.config.baseLocale.languageTag,
        'locales': {
          ...fileCollection.files.map((f) => f.locale.languageTag),
        }.toList(),
      });
    },
  );

  server.registerTool(
    'get-wip-translations',
    description:
        'Gets the translations found in source code (in base locale) that should be translated',
    callback: (args, extra) async {
      final map = await readWipMapFromFileSystem();
      return CallToolResult.fromStructuredContent(map);
    },
  );

  server.registerTool(
    'get-missing-translations',
    description:
        'Gets the translations that existing in base locale but not in secondary locales.',
    outputSchema: JsonSchema.object(
      description:
'''A map where each key is a locale identifier (e.g., "de", "fr-CA")
and the value is a nested map containing the missing translation keys and their corresponding base locale strings.''',
    ),
    callback: (args, extra) async {
      final fileCollection = SlangFileCollectionBuilder.readFromFileSystem(
        verbose: false,
      );

      final translationMap = await TranslationMapBuilder.build(
        fileCollection: fileCollection,
      );

      // build translation model
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

      return CallToolResult.fromStructuredContent({
        for (final entry in result.entries) entry.key.languageTag: entry.value,
      });
    },
  );

  server.registerTool(
    'apply-wip-translations',
    description:
        '''Adds the found translations from source code to the actual translation files.
Note: Running apply-translations with **base locale** is not needed afterwards.''',
    callback: (args, extra) async {
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

      return CallToolResult.fromContent([
        TextContent(text: 'OK'),
      ]);
    },
  );

  server.registerTool(
    'apply-translations',
    description:
        'Adds translations from a provided map to the actual translation files',
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

      final fileCollection = SlangFileCollectionBuilder.readFromFileSystem(
        verbose: false,
      );

      final translationMap = await TranslationMapBuilder.build(
        fileCollection: fileCollection,
      );

      await applyTranslationsForOneLocale(
        fileCollection: fileCollection,
        applyLocale: I18nLocale.fromString(locale),
        baseTranslations: translationMap[fileCollection.config.baseLocale]!,
        newTranslations: translations,
      );

      // Generate after applying with new translations
      await generateTranslations(
        fileCollection: SlangFileCollectionBuilder.readFromFileSystem(
          verbose: false,
        ),
      );

      return CallToolResult.fromContent([
        TextContent(text: 'OK'),
      ]);
    },
  );

  await server.connect(StdioServerTransport());

  print('Running slang_mcp! v0.0.1');
}
