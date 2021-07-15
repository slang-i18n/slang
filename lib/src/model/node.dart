import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/context_type.dart';
import 'package:fast_i18n/src/utils.dart';

/// the super class of every node
abstract class Node {
  static const KEY_DELIMITER = ','; // used by context
}

enum ObjectNodeType {
  classType, // represent this object as class
  map, // as Map<String,dynamic>
  pluralCardinal, // as function
  pluralOrdinal, // as function
  context, // as function
}

class ObjectNode extends Node {
  final Map<String, Node> entries;
  final ObjectNodeType type;
  final bool plainStrings;
  final ContextType? contextHint; // to save computing power by calc only once

  ObjectNode(this.entries, this.type, this.contextHint)
      : plainStrings = entries.values
            .every((child) => child is TextNode && child.params.isEmpty);

  @override
  String toString() => entries.toString();
}

class ListNode extends Node {
  final List<Node> entries;
  final bool plainStrings;

  ListNode(this.entries)
      : plainStrings =
            entries.every((child) => child is TextNode && child.params.isEmpty);

  @override
  String toString() => entries.toString();
}

class TextNode extends Node {
  /// Content of the text node, normalized.
  /// Will be written to .g.dart as is.
  late final String content;

  /// Set of parameters.
  /// Hello {name}, I am {age} years old -> {'name', 'age'}
  late final Set<String> params;

  TextNode(
    String content,
    StringInterpolation interpolation,
    String localeEnum,
  ) {
    String contentNormalized = content
        .replaceAll('\r\n', '\\n') // (linebreak 1) -> \n
        .replaceAll('\n', '\\n') // (linebreak 2) -> \n
        .replaceAll('\'', '\\\''); // ' -> \'

    // parse arguments, modify [contentNormalized] according to interpolation
    switch (interpolation) {
      case StringInterpolation.dart:
        this.params = Utils.argumentsDartRegex
            .allMatches(contentNormalized)
            .map((e) => e.group(2))
            .cast<String>()
            .toSet(); // remove duplicates
        break;
      case StringInterpolation.braces:
        params = Set<String>();
        contentNormalized = contentNormalized
            .replaceAllMapped(Utils.argumentsBracesRegex, (match) {
          if (match.group(1) == '\\') {
            return '{${match.group(2)}}'; // escape
          }

          params.add(match.group(2)!);

          if (match.group(3) != null) {
            // ${...}
            return '${match.group(1)}\${${match.group(2)}}${match.group(3)}';
          } else {
            // $...
            return '${match.group(1)}\$${match.group(2)}';
          }
        });
        break;
      case StringInterpolation.doubleBraces:
        params = Set<String>();
        contentNormalized = contentNormalized
            .replaceAllMapped(Utils.argumentsDoubleBracesRegex, (match) {
          if (match.group(1) == '\\') {
            return '{{${match.group(2)}}}'; // escape
          }

          params.add(match.group(2)!);

          if (match.group(3) != null) {
            // ${...}
            return '${match.group(1)}\${${match.group(2)}}${match.group(3)}';
          } else {
            // $...
            return '${match.group(1)}\$${match.group(2)}';
          }
        });
    }

    // detect linked translations
    this.content =
        contentNormalized.replaceAllMapped(Utils.linkedRegex, (match) {
      return '\${$localeEnum.translations.${match.group(1)}}';
    });
  }

  @override
  String toString() {
    if (params.isEmpty)
      return content;
    else
      return '$params => $content';
  }
}
