import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/utils.dart';

/// the super class of every node
class Node {}

enum ObjectNodeType {
  classType, // represent this object as class
  map, // as Map<String,dynamic>
  pluralCardinal, // as function
  pluralOrdinal, // as function
}

class ObjectNode extends Node {
  final Map<String, Node> entries;
  final ObjectNodeType type;
  final bool plainStrings;

  ObjectNode(this.entries, this.type)
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
  final String content;
  final List<String> params;

  TextNode(String content, StringInterpolation interpolation)
      : content = content
            .replaceAll('\r\n', '\\n')
            .replaceAll('\n', '\\n')
            .replaceAll('\'', '\\\'')
            .digest(interpolation),
        params = _findArguments(content, interpolation).toSet().toList();

  @override
  String toString() {
    if (params.isEmpty)
      return content;
    else
      return '$params => $content';
  }
}

/// find arguments like $variableName in the given string
/// this can be escaped with backslash
///
/// examples:
/// 'hello $name' => ['name']
/// 'hello \$name => []
/// 'my name is $name and I am $age years old' => ['name', 'age']
/// 'my name is ${name} and I am ${age} years old' => ['name', 'age']
List<String> _findArguments(String content, StringInterpolation interpolation) {
  return interpolation.regex
      .allMatches(content)
      .map((e) => e.group(2))
      .where((e) => e != null)
      .cast<String>()
      .toList();
}
