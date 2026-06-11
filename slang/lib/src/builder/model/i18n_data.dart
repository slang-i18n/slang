import 'package:slang/src/builder/builder/translation_model_builder.dart';
import 'package:slang/src/builder/model/context_type.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/interface.dart';
import 'package:slang/src/builder/model/node.dart';
import 'package:slang/src/builder/utils/node_utils.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';

class FallbackLocale {
  /// Usually the base locale.
  /// If there is a language-only locale (e.g. "de")
  /// and a region-specific locale (e.g. "de-CH"),
  /// the language-only ("de") locale will be used as fallback
  /// for the region-specific locale.
  final I18nLocale locale;

  /// Whether or not to fallback to this locale if a translation is missing.
  /// True if [GenerateFallbackStrategy.baseLocale].
  final bool fallback;

  FallbackLocale({
    required this.locale,
    required this.fallback,
  });
}

/// represents one locale and its localized strings
class I18nData implements BuildModelResult {
  final bool base; // whether or not this is the base locale
  final I18nLocale locale; // the locale (the part after the underscore)
  final FallbackLocale fallbackLocale;
  final I18nData? fallbackData; // the actual fallback data, null if no fallback
  final CodeVisibility classVisibility;
  final CodeVisibility constructorVisibility;

  @override
  final ObjectNode root; // the actual strings

  @override
  late final flatMap = root.toFlatMap();

  @override
  final List<PopulatedContextType> contexts; // detected context types

  @override
  final List<Interface> interfaces; // detected interfaces

  @override
  final Map<String, String> types; // detected types, values are rendered as is

  I18nData({
    required this.base,
    required this.locale,
    required this.fallbackLocale,
    required this.fallbackData,
    required this.classVisibility,
    required this.constructorVisibility,
    required this.root,
    required this.contexts,
    required this.interfaces,
    required this.types,
  });

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
