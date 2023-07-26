import 'dart:convert';

import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang_gpt/model/gpt_config.dart';
import 'package:slang_gpt/model/gpt_prompt.dart';
import 'package:slang_gpt/util/locales.dart';

/// Returns the prompts that should be sent to GPT.
/// There can be multiple prompts if the input is too long.
List<GptPrompt> getPrompts({
  required RawConfig rawConfig,
  required I18nLocale targetLocale,
  required GptConfig config,
  required String? namespace,
  required Map<String, dynamic> translations,
}) {
  final systemPrompt = _getSystemPrompt(
    rawConfig: rawConfig,
    targetLocale: targetLocale,
    config: config,
    namespace: namespace,
  );
  final systemPromptLength = systemPrompt.length;

  final prompts = <GptPrompt>[];
  Map<String, dynamic> currentTranslationWindow = {};
  for (final entry in translations.entries) {
    if (currentTranslationWindow.isEmpty) {
      currentTranslationWindow[entry.key] = entry.value;
      continue;
    }

    final currentTranslation = jsonEncode(currentTranslationWindow);
    currentTranslationWindow[entry.key] = entry.value;
    final nextTranslation = jsonEncode(currentTranslationWindow);

    if (systemPromptLength + nextTranslation.length > config.maxInputLength) {
      prompts.add(GptPrompt(
        system: systemPrompt,
        user: currentTranslation,

        // currentTranslationWindow has been changed already
        userJSON: jsonDecode(currentTranslation),
      ));
      currentTranslationWindow = {
        entry.key: entry.value,
      };
    }
  }

  if (currentTranslationWindow.isNotEmpty) {
    // add the last prompt
    prompts.add(GptPrompt(
      system: systemPrompt,
      user: jsonEncode(currentTranslationWindow),
      userJSON: currentTranslationWindow,
    ));
  }

  return prompts;
}

String _getSystemPrompt({
  required RawConfig rawConfig,
  required I18nLocale targetLocale,
  required GptConfig config,
  required String? namespace,
}) {
  final String interpolationHint;
  switch (rawConfig.stringInterpolation) {
    case StringInterpolation.dart:
      interpolationHint = r'${parameter} or $parameter';
      break;
    case StringInterpolation.braces:
      interpolationHint = r'{parameter}';
      break;
    case StringInterpolation.doubleBraces:
      interpolationHint = r'{{parameter}}';
      break;
  }

  final String namespaceHint;
  if (namespace != null) {
    namespaceHint = ' the "$namespace" part of';
  } else {
    namespaceHint = '';
  }

  return '''The user wants to internationalize$namespaceHint the app. The user will provide you with a JSON file containing the ${getEnglishName(rawConfig.baseLocale)} strings.
You will translate it to ${getEnglishName(targetLocale)}.
Parameters are interpolated with $interpolationHint.
Linked translations are denoted with the "@:path0.path1" syntax.

Here is the app description. Respect this context when translating:
${config.description}''';
}
