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
  final String content;

  /// List of parameters.
  /// Hello {name}, I am {age} years old -> ['name', 'age']
  final List<String> params;

  TextNode(String content, StringInterpolation interpolation)
      : content = content
            .replaceAll('\r\n', '\\n') // (linebreak 1) -> \n
            .replaceAll('\n', '\\n') // (linebreak 2) -> \n
            .replaceAll('\'', '\\\'') // ' -> \'
            .normalizeStringInterpolation(interpolation),
        params = content.parseArguments(interpolation);

  @override
  String toString() {
    if (params.isEmpty)
      return content;
    else
      return '$params => $content';
  }
}

extension StringExt on String {
  /// transforms {arg} or {{arg}} to ${arg}
  String normalizeStringInterpolation(StringInterpolation from) {
    switch (from) {
      case StringInterpolation.dart:
        return this; // no change
      case StringInterpolation.braces:
        return replaceAllMapped(Utils.argumentsBracesRegex, (match) {
          if (match.group(1) == '\\') {
            return '{${match.group(2)}}'; // escape
          }
          return '${match.group(1)}\${${match.group(2)}}';
        });
      case StringInterpolation.doubleBraces:
        return replaceAllMapped(Utils.argumentsDoubleBracesRegex, (match) {
          if (match.group(1) == '\\') {
            return '{{${match.group(2)}}}'; // escape
          }
          return '${match.group(1)}\${${match.group(2)}}';
        });
    }
  }

  /// find arguments like $variableName in the given string
  /// this can be escaped with backslash
  ///
  /// examples:
  /// 'hello $name' => ['name']
  /// 'hello \$name => []
  /// 'my name is $name and I am $age years old' => ['name', 'age']
  List<String> parseArguments(StringInterpolation interpolation) {
    final RegExp regex;
    switch (interpolation) {
      case StringInterpolation.dart:
        regex = Utils.argumentsDartRegex;
        break;
      case StringInterpolation.braces:
        regex = Utils.argumentsBracesRegex;
        break;
      case StringInterpolation.doubleBraces:
        regex = Utils.argumentsDoubleBracesRegex;
        break;
    }

    return regex
        .allMatches(this)
        .map((e) {
          if (e.group(1) == '\\') return null; // escaped
          return e.group(2);
        })
        .where((e) => e != null)
        .cast<String>()
        .toSet() // remove duplicates
        .toList();
  }
}
