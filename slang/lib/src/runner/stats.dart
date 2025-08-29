import 'package:slang/src/builder/builder/translation_model_list_builder.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/node.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:slang/src/builder/model/translation_map.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/utils/log.dart' as log;

StatsResult getStats({
  required RawConfig rawConfig,
  required TranslationMap translationMap,
}) {
  // build translation model
  final translationModelList = TranslationModelListBuilder.build(
    rawConfig,
    translationMap,
  );

  // use translation model and calculate statistics
  Map<I18nLocale, StatsLocaleResult> result = {};
  for (final localeData in translationModelList) {
    final keyCount = _countKeys(localeData.root) - 1; // don't include root
    final translationCount = _countTranslations(localeData.root);
    final wordCount = _countWords(localeData.root);
    final characterCount = _countCharacters(localeData.root);
    result[localeData.locale] = StatsLocaleResult(
      keyCount: keyCount,
      translationCount: translationCount,
      wordCount: wordCount,
      characterCount: characterCount,
    );
  }

  return StatsResult(
    localeStats: result,
    globalStats: StatsLocaleResult(
      keyCount: result.values.fold(0, (prev, curr) => prev + curr.keyCount),
      translationCount:
          result.values.fold(0, (prev, curr) => prev + curr.translationCount),
      wordCount: result.values.fold(0, (prev, curr) => prev + curr.wordCount),
      characterCount:
          result.values.fold(0, (prev, curr) => prev + curr.characterCount),
    ),
  );
}

class StatsResult {
  final Map<I18nLocale, StatsLocaleResult> localeStats;
  final StatsLocaleResult globalStats;

  StatsResult({
    required this.localeStats,
    required this.globalStats,
  });

  void printResult() {
    final specialCharacters = ',.?!\'¿¡';
    localeStats.forEach((locale, stats) {
      log.info('[${locale.languageTag}]');
      log.info(' - ${stats.keyCount} keys (including intermediate keys)');
      log.info(' - ${stats.translationCount} translations (leaves only)');
      log.info(' - ${stats.wordCount} words');
      log.info(
          ' - ${stats.characterCount} characters (ex. [$specialCharacters])');
    });
    log.info('[total]');
    log.info(' - ${globalStats.keyCount} keys (including intermediate keys)');
    log.info(' - ${globalStats.translationCount} translations (leaves only)');
    log.info(' - ${globalStats.wordCount} words');
    log.info(
        ' - ${globalStats.characterCount} characters (ex. [$specialCharacters])');
  }
}

class StatsLocaleResult {
  final int keyCount;
  final int translationCount;
  final int wordCount;
  final int characterCount;

  StatsLocaleResult({
    required this.keyCount,
    required this.translationCount,
    required this.wordCount,
    required this.characterCount,
  });
}

/// Count every key
int _countKeys(Node node) {
  if (node is TextNode) {
    return 1;
  } else if (node is ListNode) {
    int sum = 0;
    for (Node entry in node.entries) {
      sum += _countKeys(entry);
    }
    return 1 + sum;
  } else if (node is ObjectNode) {
    int sum = 0;
    for (Node entry in node.entries.values) {
      sum += _countKeys(entry);
    }
    return 1 + sum;
  } else if (node is PluralNode) {
    return 1 + node.quantities.entries.length;
  } else if (node is ContextNode) {
    return 1 + node.entries.entries.length;
  } else {
    // should not happen
    return 0;
  }
}

/// Only count leaves
int _countTranslations(Node node) {
  if (node is TextNode) {
    return 1;
  } else if (node is ListNode) {
    int sum = 0;
    for (Node entry in node.entries) {
      sum += _countTranslations(entry);
    }
    return sum;
  } else if (node is ObjectNode) {
    int sum = 0;
    for (Node entry in node.entries.values) {
      sum += _countTranslations(entry);
    }
    return sum;
  } else if (node is PluralNode) {
    return node.quantities.entries.length;
  } else if (node is ContextNode) {
    return node.entries.entries.length;
  } else {
    // should not happen
    return 0;
  }
}

/// Count words of all leaves
int _countWords(Node root) {
  return _sumOfEveryTextNode(
    node: root,
    valueCallback: (textNode) {
      return textNode.raw.split(RegexUtils.spaceRegex).length;
    },
  );
}

/// Count characters of all leaves
int _countCharacters(Node root) {
  return _sumOfEveryTextNode(
    node: root,
    valueCallback: (textNode) {
      return textNode.raw
          .replaceAll(',', '')
          .replaceAll('.', '')
          .replaceAll('?', '')
          .replaceAll('!', '')
          .replaceAll('\'', '')
          .replaceAll('¿', '')
          .replaceAll('¡', '')
          .length;
    },
  );
}

/// Helper function to calculate the sum of every [TextNode]
/// The valuation is dependent on the [valueCallback] parameter.
int _sumOfEveryTextNode({
  required Node node,
  required int Function(TextNode) valueCallback,
}) {
  if (node is TextNode) {
    return valueCallback(node);
  } else if (node is ListNode) {
    int sum = 0;
    for (Node entry in node.entries) {
      sum += _sumOfEveryTextNode(node: entry, valueCallback: valueCallback);
    }
    return sum;
  } else if (node is ObjectNode) {
    int sum = 0;
    for (Node entry in node.entries.values) {
      sum += _sumOfEveryTextNode(node: entry, valueCallback: valueCallback);
    }
    return sum;
  } else if (node is PluralNode) {
    int sum = 0;
    for (Node entry in node.quantities.values) {
      sum += _sumOfEveryTextNode(node: entry, valueCallback: valueCallback);
    }
    return sum;
  } else if (node is ContextNode) {
    int sum = 0;
    for (Node entry in node.entries.values) {
      sum += _sumOfEveryTextNode(node: entry, valueCallback: valueCallback);
    }
    return sum;
  } else {
    // should not happen
    return 0;
  }
}
