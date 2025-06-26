import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
// ignore: implementation_imports
import 'package:slang/src/builder/builder/slang_file_collection_builder.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/decoder/base_decoder.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/model/i18n_locale.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/model/slang_file_collection.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/utils/file_utils.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/utils/map_utils.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/utils/path_utils.dart';
// ignore: implementation_imports
import 'package:slang/src/runner/apply.dart';
import 'package:slang_openai/constants/default_values.dart';
import 'package:slang_openai/model/openai_config.dart';
import 'package:slang_openai/model/openai_prompt.dart';
import 'package:slang_openai/model/openai_response.dart';
import 'package:slang_openai/model/provider.dart';
import 'package:slang_openai/prompt/prompt.dart';
import 'package:slang_openai/util/locales.dart';
import 'package:slang_openai/util/logger.dart';
import 'package:slang_openai/util/maps.dart';

const _errorKey = '!error';

/// Runs the Openai translation script.
Future<void> runOpenai(List<String> arguments) async {
  print('Calling OpenAI API for slang...');

  // Parse command line arguments
  Provider? provider;
  String? apiKey;
  List<I18nLocale>? targetLocales;
  String? outDir;
  bool debug = false;
  bool full = false;
  for (final a in arguments) {
    if (a.startsWith('--provider=')) {
      provider = Provider.fromString(a.substring(11));
      if (provider == null) {
        print(
            'ERROR: Invalid provider specified: ${a.substring(11)}. Options are: '
            '${Provider.values.map((e) => e.name).join(', ')}.');
        exit(-1);
      }
    } else if (a.startsWith('--api-key=')) {
      apiKey = a.substring(10);
    } else if (a.startsWith('--target=')) {
      final id = a.substring(9);
      final preset = getPreset(id);
      if (preset != null) {
        targetLocales = preset;
      } else {
        targetLocales = [I18nLocale.fromString(id)];
      }
    } else if (a.startsWith('--outdir=')) {
      outDir = a.substring(9);
    } else if (a == '-f' || a == '--full') {
      full = true;
    } else if (a == '-d' || a == '--debug') {
      debug = true;
    }
  }

  final fileCollection = SlangFileCollectionBuilder.readFromFileSystem(
    verbose: false,
  );

  final openaiConfig = OpenaiConfig.fromMap(fileCollection.config.rawMap);

  late final String fallbackUrl;
  switch (provider) {
    case Provider.openai:
      // Set fallback URL to OpenAI URL
      fallbackUrl = kOpenaiUrl;

      print('');
      if (openaiConfig.url != null && openaiConfig.url != kOpenaiUrl) {
        print('WARNING: OpenAI URL from preset is overridden by config URL!');
      } else {
        print('Using OpenAI preset.');
      }

    case Provider.openrouter:
      // Set fallback URL to OpenRouter URL
      fallbackUrl = kOpenrouterUrl;

      print('');
      if (openaiConfig.url != null && openaiConfig.url != kOpenrouterUrl) {
        print('WARNING: '
            'OpenRouter URL from preset is overridden by config URL!');
      } else {
        print('Using OpenRouter preset.');
      }
    case Provider.ollama:
      // Set fallback URL to Ollama URL
      fallbackUrl = kOllamaUrl;

      print('');
      if (openaiConfig.url != null && openaiConfig.url != kOllamaUrl) {
        print('WARNING: Ollama URL from preset is overridden by config URL!');
      } else {
        print('Using Ollama preset.');
      }
    case null:
      // If no provider is specified, default to OpenAI
      fallbackUrl = kOpenaiUrl;
  }

  // Check api key validity
  final finalUrl = openaiConfig.url ?? fallbackUrl;
  if (apiKey == null) {
    if (finalUrl == kOpenaiUrl || finalUrl == kOpenrouterUrl) {
      print('');
      print('ERROR: No API key provided!');
      exit(-1);
    }

    // Do not warn about missing API key for Ollama, as it does not require one.
    if (finalUrl != kOllamaUrl) {
      print('');
      print('WARNING: No API key provided!');
    }
  }

  if (targetLocales != null) {
    print('');
    print('Target: ${targetLocales.map((e) => e.languageTag).join(', ')}\n');
  }

  if (outDir == null) {
    outDir = fileCollection.config.inputDirectory;
    if (outDir == null) {
      throw 'input_directory or --outdir=<path> must be specified.';
    }
  }

  print('Configs:');
  print(' - URL: $finalUrl');
  print(' - Model: ${openaiConfig.model}');
  print(' - Max input length: '
      '${openaiConfig.maxInputLength ?? kMaxInputLength}');
  print(' - Temperature: ${openaiConfig.temperature ?? 'default'}');
  print(' - Description: ${openaiConfig.description}');

  if (openaiConfig.excludes.isNotEmpty) {
    print(
        'Excludes: ${openaiConfig.excludes.map((e) => e.languageTag).join(', ')}');
  }

  int promptCount = 0;
  int inputTokens = 0;
  int outputTokens = 0;
  for (final file in fileCollection.files) {
    if (file.locale != fileCollection.config.baseLocale) {
      // Only use base locale as source
      continue;
    }

    final raw = await file.read();
    final Map<String, dynamic> originalTranslations;
    try {
      originalTranslations =
          BaseDecoder.decodeWithFileType(fileCollection.config.fileType, raw);
    } on FormatException catch (e) {
      throw 'File: ${file.path}\n$e';
    }

    if (targetLocales == null) {
      // translate to existing locales
      for (final destFile in fileCollection.files) {
        if (openaiConfig.excludes.contains(destFile.locale)) {
          // skip excluded locales
          continue;
        }

        if (fileCollection.config.namespaces &&
            destFile.namespace != file.namespace) {
          // skip files in different namespaces
          continue;
        }

        if (destFile.locale == file.locale) {
          // skip same locale
          continue;
        }

        final metrics = await _translate(
          fileCollection: fileCollection,
          openaiConfig: openaiConfig,
          targetLocale: destFile.locale,
          fallbackUrl: fallbackUrl,
          outDir: outDir,
          full: full,
          debug: debug,
          file: file,
          originalTranslations: originalTranslations,
          apiKey: apiKey,
          promptCount: promptCount,
        );

        promptCount = metrics.endPromptCount;
        inputTokens += metrics.inputTokens;
        outputTokens += metrics.outputTokens;
      }
    } else {
      // translate to specified locales (they may not exist yet)
      for (final targetLocale in targetLocales) {
        final metrics = await _translate(
          fileCollection: fileCollection,
          openaiConfig: openaiConfig,
          targetLocale: targetLocale,
          fallbackUrl: fallbackUrl,
          outDir: outDir,
          full: full,
          debug: debug,
          file: file,
          originalTranslations: originalTranslations,
          apiKey: apiKey,
          promptCount: promptCount,
        );

        promptCount = metrics.endPromptCount;
        inputTokens += metrics.inputTokens;
        outputTokens += metrics.outputTokens;
      }
    }
  }

  print('');
  print('Summary:');
  print(' -> Total requests: $promptCount');
  print(' -> Total input tokens: $inputTokens');
  print(' -> Total output tokens: $outputTokens');
}

class TranslateMetrics {
  final int endPromptCount;
  final int inputTokens;
  final int outputTokens;

  const TranslateMetrics({
    required this.endPromptCount,
    required this.inputTokens,
    required this.outputTokens,
  });
}

/// Translates a file to a target locale.
Future<TranslateMetrics> _translate({
  required SlangFileCollection fileCollection,
  required OpenaiConfig openaiConfig,
  required I18nLocale targetLocale,
  required String fallbackUrl,
  required String outDir,
  required bool full,
  required bool debug,
  required TranslationFile file,
  required Map<String, dynamic> originalTranslations,
  required String? apiKey,
  required int promptCount,
}) async {
  print('');
  print(
      'Translating <${file.locale.languageTag}> to <${targetLocale.languageTag}> for ${file.path} ...');

  // existing translations of target locale
  Map<String, dynamic> existingTranslations = {};
  String targetPath = PathUtils.withFileName(
    directoryPath: outDir,
    fileName:
        '${file.namespace}_${targetLocale.languageTag}${fileCollection.config.inputFilePattern}',
    pathSeparator: Platform.pathSeparator,
  );
  if (!full) {
    for (final destFile in fileCollection.files) {
      if ((!fileCollection.config.namespaces ||
              (destFile.namespace == file.namespace)) &&
          destFile.locale == targetLocale) {
        final raw = await destFile.read();
        try {
          existingTranslations = BaseDecoder.decodeWithFileType(
              fileCollection.config.fileType, raw);
          targetPath = destFile.path;
          print(' -> With partial translations from ${destFile.path}');
        } on FormatException catch (e) {
          throw 'File: ${destFile.path}\n$e';
        }
        break;
      }
    }
  }

  final inputTranslations = MapUtils.subtract(
    target: originalTranslations,
    other: existingTranslations,
  );

  // We assume that these translations already exists in the target locale.
  removeignoreOpenai(map: inputTranslations);

  // extract original comments but keep them in the inputTranslations
  // we will add the original comments later again
  final comments = extractComments(
    map: inputTranslations,
    remove: false,
  );

  if (inputTranslations.isEmpty) {
    print(' -> No new translations');
    return TranslateMetrics(
      endPromptCount: promptCount,
      inputTokens: 0,
      outputTokens: 0,
    );
  }

  final prompts = getPrompts(
    rawConfig: fileCollection.config,
    targetLocale: targetLocale,
    config: openaiConfig,
    namespace: fileCollection.config.namespaces ? file.namespace : null,
    translations: inputTranslations,
  );

  Map<String, dynamic> result = {};
  int inputTokens = 0;
  int outputTokens = 0;
  for (final prompt in prompts) {
    promptCount++;

    print(' -> Request #$promptCount');
    final response = await _doRequest(
      url: openaiConfig.url ?? fallbackUrl,
      model: openaiConfig.model,
      temperature: openaiConfig.temperature,
      apiKey: apiKey,
      prompt: prompt,
    );

    final hasError = response.jsonMessage.containsKey(_errorKey);

    if (debug || hasError) {
      if (hasError) {
        print(' -> Error while parsing JSON. Writing to log file.');
      }
      logOpenaiRequest(
        fromLocale: fileCollection.config.baseLocale,
        toLocale: targetLocale,
        fromFile: file.path,
        toFile: targetPath,
        outDir: outDir,
        promptCount: promptCount,
        prompt: prompt,
        response: response,
      );
    }

    if (!hasError) {
      result = applyMapRecursive(
        baseMap: originalTranslations,
        newMap: response.jsonMessage,
        oldMap: result,
        verbose: false,
      );
    }

    inputTokens += response.promptTokens;
    outputTokens += response.completionTokens;
  }

  // add existing translations
  result = applyMapRecursive(
    baseMap: originalTranslations,
    newMap: existingTranslations,
    oldMap: result,
    verbose: false,
  );

  // add comments from base locale to target locale
  result = applyMapRecursive(
    baseMap: originalTranslations,
    newMap: comments,
    oldMap: result,
    verbose: false,
  );

  FileUtils.writeFileOfType(
    fileType: fileCollection.config.fileType,
    path: targetPath,
    content: result,
  );
  print(' -> Output: $targetPath');

  return TranslateMetrics(
    endPromptCount: promptCount,
    inputTokens: inputTokens,
    outputTokens: outputTokens,
  );
}

/// Sends a prompt to an OpenAI compatible API and returns the response.
Future<OpenaiResponse> _doRequest({
  required String url,
  required String model,
  required double? temperature,
  required String? apiKey,
  required OpenaiPrompt prompt,
}) async {
  final response = await http.post(
    Uri.parse(url),
    headers: {
      if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'stream': false,
      'model': model,
      if (temperature != null) 'temperature': temperature,
      'messages': [
        {
          'role': 'system',
          'content': prompt.system,
        },
        {
          'role': 'user',
          'content': prompt.user,
        }
      ],
    }),
  );

  if (response.statusCode != 200) {
    throw 'Error: ${response.statusCode} ${response.body}';
  }

  final rawMap = jsonDecode(utf8.decode(response.bodyBytes));
  print(' -> Response: $rawMap');
  final rawMessage = rawMap['choices'][0]['message']['content'] as String;
  Map<String, dynamic> jsonMessage;
  try {
    jsonMessage = _jsonFromMessage(rawMessage);
  } catch (e) {
    jsonMessage = {
      _errorKey: 'Error: ${e.toString()}',
    };
  }
  return OpenaiResponse(
    rawMessage: rawMessage,
    jsonMessage: jsonMessage,
    promptTokens: rawMap['usage']['prompt_tokens'] as int,
    completionTokens: rawMap['usage']['completion_tokens'] as int,
    totalTokens: rawMap['usage']['total_tokens'] as int,
  );
}

/// The model may respond with additional information in the message.
/// This method extracts the JSON part from the message.
Map<String, dynamic> _jsonFromMessage(String message) {
  final startIndex = message.indexOf('{');
  final endIndex = message.lastIndexOf('}');

  return jsonDecode(message.substring(startIndex, endIndex + 1));
}
