import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:slang/builder/builder/slang_file_collection_builder.dart';
import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/slang_file_collection.dart';
import 'package:slang/builder/utils/file_utils.dart';
import 'package:slang/builder/utils/map_utils.dart';
import 'package:slang/builder/utils/path_utils.dart';
import 'package:slang/runner/apply.dart';
import 'package:slang_gpt/model/gpt_config.dart';
import 'package:slang_gpt/model/gpt_model.dart';
import 'package:slang_gpt/model/gpt_prompt.dart';
import 'package:slang_gpt/model/gpt_response.dart';
import 'package:slang_gpt/prompt/prompt.dart';
import 'package:slang_gpt/util/locales.dart';
import 'package:slang_gpt/util/logger.dart';
import 'package:slang_gpt/util/maps.dart';

const _errorKey = '!error';

Future<void> runGpt(List<String> arguments) async {
  print('Running GPT for slang...');

  String? apiKey;
  List<I18nLocale>? targetLocales;
  String? outDir;
  bool verbose = false;
  bool full = false;
  for (final a in arguments) {
    if (a.startsWith('--api-key=')) {
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
    } else if (a == '-v' || a == '--verbose') {
      verbose = true;
    }
  }

  if (apiKey == null) {
    throw 'Missing API key. Specify it with --api-key=...';
  }

  if (targetLocales != null) {
    print('');
    print('Target: ${targetLocales.map((e) => e.languageTag).join(', ')}\n');
  }

  final fileCollection = SlangFileCollectionBuilder.readFromFileSystem(
    verbose: false,
  );

  if (outDir == null) {
    outDir = fileCollection.config.inputDirectory;
    if (outDir == null) {
      throw 'input_directory or --outdir=<path> must be specified.';
    }
  }

  final gptConfig = GptConfig.fromMap(fileCollection.config.rawMap);
  print(
    'GPT config: ${gptConfig.model.id} / ${gptConfig.maxInputLength} max input length',
  );

  int promptCount = 0;
  for (final file in fileCollection.files) {
    if (file.locale != fileCollection.config.baseLocale) {
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
        if ((!fileCollection.config.namespaces ||
                (destFile.namespace == file.namespace)) &&
            destFile.locale != fileCollection.config.baseLocale) {
          promptCount = await _translate(
            fileCollection: fileCollection,
            gptConfig: gptConfig,
            targetLocale: destFile.locale,
            outDir: outDir,
            full: full,
            verbose: verbose,
            file: file,
            originalTranslations: originalTranslations,
            apiKey: apiKey,
            promptCount: promptCount,
          );
        }
      }
    } else {
      // translate to specified locales (they may not exist yet)
      for (final targetLocale in targetLocales) {
        promptCount = await _translate(
          fileCollection: fileCollection,
          gptConfig: gptConfig,
          targetLocale: targetLocale,
          outDir: outDir,
          full: full,
          verbose: verbose,
          file: file,
          originalTranslations: originalTranslations,
          apiKey: apiKey,
          promptCount: promptCount,
        );
      }
    }
  }
}

Future<int> _translate({
  required SlangFileCollection fileCollection,
  required GptConfig gptConfig,
  required I18nLocale targetLocale,
  required String outDir,
  required bool full,
  required bool verbose,
  required TranslationFile file,
  required Map<String, dynamic> originalTranslations,
  required String apiKey,
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

  removeIgnoreMissing(map: inputTranslations);

  // extract original comments but keep them in the inputTranslations
  // we will add the original comments later again
  final comments = extractComments(
    map: inputTranslations,
    remove: false,
  );

  if (inputTranslations.isEmpty) {
    print(' -> No new translations');
    return promptCount;
  }

  final prompts = getPrompts(
    rawConfig: fileCollection.config,
    targetLocale: targetLocale,
    config: gptConfig,
    namespace: fileCollection.config.namespaces ? file.namespace : null,
    translations: inputTranslations,
  );

  Map<String, dynamic> result = {};
  for (final prompt in prompts) {
    promptCount++;

    print(' -> Request #$promptCount');
    final response = await _doRequest(
      model: gptConfig.model,
      apiKey: apiKey,
      prompt: prompt,
    );

    final hasError = response.jsonMessage.containsKey(_errorKey);

    if (verbose || hasError) {
      if (hasError) {
        print(' -> Error while parsing JSON. Writing to log file.');
      }
      logGptRequest(
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
  }

  // add existing translations
  result = applyMapRecursive(
    baseMap: originalTranslations,
    newMap: existingTranslations,
    oldMap: result,
    verbose: false,
  );

  // add comments
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

  return promptCount;
}

/// Sends a prompt to a GPT provider and returns the response.
Future<GptResponse> _doRequest({
  required GptModel model,
  required String apiKey,
  required GptPrompt prompt,
}) async {
  switch (model.provider) {
    case GptProvider.openai:
      final response = await http.post(
        Uri.https('api.openai.com', 'v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model.id,
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
      final rawMessage = rawMap['choices'][0]['message']['content'] as String;
      Map<String, dynamic> jsonMessage;
      try {
        jsonMessage = _jsonFromMessage(rawMessage);
      } catch (e) {
        jsonMessage = {
          _errorKey: 'Error: ${e.toString()}',
        };
      }
      return GptResponse(
        rawMessage: rawMessage,
        jsonMessage: jsonMessage,
        promptTokens: rawMap['usage']['prompt_tokens'] as int,
        completionTokens: rawMap['usage']['completion_tokens'] as int,
        totalTokens: rawMap['usage']['total_tokens'] as int,
      );
  }
}

/// The GPT model may respond with additional information in the message.
/// This method extracts the JSON part from the message.
Map<String, dynamic> _jsonFromMessage(String message) {
  final startIndex = message.indexOf('{');
  final endIndex = message.lastIndexOf('}');

  return jsonDecode(message.substring(startIndex, endIndex + 1));
}
