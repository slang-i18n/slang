import 'package:slang/builder/model/build_config.dart';
import 'package:slang/builder/model/i18n_data.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/translation_map.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/model/stats_result.dart';
import 'package:slang/builder/utils/regex_utils.dart';

import 'builder/translation_model_builder.dart';

class StatsFacade {
  static StatsResult parse({
    required BuildConfig buildConfig,
    required TranslationMap translationMap,
    bool showPluralHint = false,
  }) {
    final List<I18nData> translationList =
        translationMap.getEntries().map((localeEntry) {
      final locale = localeEntry.key;
      final namespaces = localeEntry.value;
      return TranslationModelBuilder.build(
        buildConfig: buildConfig,
        locale: locale,
        map: buildConfig.namespaces ? namespaces : namespaces.values.first,
      );
    }).toList();

    // sort: base locale, then all other locales
    translationList.sort(I18nData.generationComparator);

    Map<I18nLocale, StatsLocaleResult> result = {};
    translationList.forEach((localeData) {
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
    });

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
