import 'dart:convert';
import 'dart:io';

import 'package:slang/builder/model/i18n_locale.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/utils/file_utils.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/utils/path_utils.dart';
import 'package:slang_gpt/model/gpt_prompt.dart';
import 'package:slang_gpt/model/gpt_response.dart';

final _encoder = JsonEncoder.withIndent('  ');

/// Logs the GPT request and response to a file.
void logGptRequest({
  required I18nLocale fromLocale,
  required I18nLocale toLocale,
  required String fromFile,
  required String toFile,
  required String outDir,
  required int promptCount,
  required GptPrompt prompt,
  required GptResponse response,
}) {
  final path = PathUtils.withFileName(
    directoryPath: outDir,
    fileName: '_gpt_${promptCount.toString().padLeft(2, '0')}.txt',
    pathSeparator: Platform.pathSeparator,
  );
  FileUtils.writeFile(
    path: path,
    content: '''
### Meta ###
From: <${fromLocale.languageTag}> $fromFile
To: <${toLocale.languageTag}> $toFile

### Tokens ###
Input: ${response.promptTokens}
Output: ${response.completionTokens}
Total: ${response.totalTokens}

### Conversation ###

>> System:
${prompt.system}

>> User:
${prompt.user}

>> Assistant:
${response.rawMessage}

### JSON ###
Input:
${_encoder.convert(prompt.userJSON)}

Output:
${_encoder.convert(response.jsonMessage)}
''',
  );

  print(' -> Logs: $path');
}
