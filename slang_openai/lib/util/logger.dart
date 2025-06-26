import 'dart:convert';
import 'dart:io';
// ignore: implementation_imports
import 'package:slang/src/builder/model/i18n_locale.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/utils/file_utils.dart';
// ignore: implementation_imports
import 'package:slang/src/builder/utils/path_utils.dart';
import 'package:slang_openai/model/openai_prompt.dart';
import 'package:slang_openai/model/openai_response.dart';

final _encoder = JsonEncoder.withIndent('  ');

/// Logs the request and response to a file.
void logOpenaiRequest({
  required I18nLocale fromLocale,
  required I18nLocale toLocale,
  required String fromFile,
  required String toFile,
  required String outDir,
  required int promptCount,
  required OpenaiPrompt prompt,
  required OpenaiResponse response,
}) {
  final path = PathUtils.withFileName(
    directoryPath: outDir,
    fileName: '_openai_${promptCount.toString().padLeft(2, '0')}.txt',
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
