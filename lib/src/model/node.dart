import 'package:fast_i18n/src/utils.dart';

/// the super class of every node
class Node {}

class ObjectNode extends Node {
  final Map<String, Node> entries;
  final bool mapMode;
  final bool plainStrings;

  ObjectNode(this.entries, this.mapMode)
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

  TextNode(String content)
      : content = content
            .replaceAll('\r\n', '\\n')
            .replaceAll('\n', '\\n')
            .replaceAll('\'', '\\\''),
        params = _findArguments(content);

  @override
  String toString() {
    if (params.isEmpty)
      return content;
    else
      return '$params => $content';
  }
}

/// find arguments like $variableName in the given string
/// the $ can be escaped via \$
///
/// examples:
/// 'hello $name' => ['name']
/// 'hello \$name => []
/// 'my name is $name and I am $age years old' => ['name', 'age']
/// 'my name is ${name} and I am ${age} years old' => ['name', 'age']
List<String> _findArguments(String content) {
  return Utils.argumentsRegex
      .allMatches(content)
      .map((e) => e.group(2))
      .where((e) => e != null)
      .cast<String>()
      .toList();
}
