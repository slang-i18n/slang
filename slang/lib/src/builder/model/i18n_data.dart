import 'package:slang/src/builder/model/context_type.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/interface.dart';
import 'package:slang/src/builder/model/node.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';

typedef I18nDataComparator = int Function(I18nData a, I18nData b);

/// represents one locale and its localized strings
class I18nData {
  final bool base; // whether or not this is the base locale
  final I18nLocale locale; // the locale (the part after the underscore)
  final ObjectNode root; // the actual strings
  final List<PopulatedContextType> contexts; // detected context types
  final List<Interface> interfaces; // detected interfaces
  final Map<String, String> types; // detected types, values are rendered as is

  I18nData({
    required this.base,
    required this.locale,
    required this.root,
    required this.contexts,
    required this.interfaces,
    required this.types,
  });

  /// sorts base locale first, then alphabetically
  static I18nDataComparator generationComparator = (I18nData a, I18nData b) {
    if (!a.base && !b.base) {
      return a.locale.languageTag.compareTo(b.locale.languageTag);
    } else if (!a.base && b.base) {
      return 1; // move non-base to the right
    } else {
      return -1; // move base to the left
    }
  };

  /// Gets the node for a given path
  Node? getNodeByPath(String path) {
    final parts = path.split('.');
    Node? current = root;

    for (final part in parts) {
      if (current is ObjectNode) {
        current = current.entries[part];
      } else {
        return null;
      }
    }

    return current;
  }

  String? getAutodoc(String path, LeafNode? node) {
    final foundNode = node ?? getNodeByPath(path) as LeafNode?;
    if (foundNode == null) {
      return null;
    }

    return switch (foundNode) {
      TextNode textNode => '${textNode.raw.digest(this)}',
      PluralNode pluralNode => pluralNode.quantities.entries
          .map((e) => '(${e.key.name}) {${e.value.raw.digest(this)}}')
          .join(' '),
      ContextNode contextNode => contextNode.entries.entries
          .map((e) => '(${e.key}) {${e.value.raw.digest(this)}}')
          .join(' '),
      _ =>
        throw 'Unsupported node type for documentation: ${foundNode.runtimeType}',
    };
  }
}

final _whitespaceRegex = RegExp(r'\s+');

extension on String {
  String? digest(I18nData data) {
    return replaceAllMapped(RegexUtils.linkedRegex, (match) {
      final linkedPath = (match.group(1) ?? match.group(2))!;
      return data.getAutodoc(linkedPath, null) ?? match.group(0)!;
    }).replaceAll(_whitespaceRegex, ' ');
  }
}
