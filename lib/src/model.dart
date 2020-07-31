import 'package:fast_i18n/utils.dart';

const mapEscapeString = '#map';

/// represents one locale and its localized strings
class I18nData {
  final String baseName; // name of all i18n files, like strings or messages
  final bool base; // whether or not this is the base locale
  final String locale; // the locale code (the part after the underscore)
  final ObjectNode root; // the actual strings

  I18nData(this.baseName, this.locale, this.root) : base = locale.isEmpty;
}

class Value {}

class ObjectNode extends Value {
  final Map<String, Value> entries;
  final bool mapMode;

  ObjectNode(Map<String, Value> entries)
      : mapMode = entries.containsKey(mapEscapeString),
        entries = entries..remove('#map');

  @override
  String toString() => entries.toString();
}

class ListNode extends Value {
  final List<Value> entries;

  ListNode(this.entries);

  @override
  String toString() => entries.toString();
}

class TextNode extends Value {
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
List<String> _findArguments(String content) {
  String s = content.replaceAll('\\\$', ''); // remove \$
  List<String> arguments = [];
  int indexStart = s.indexOf('\$');
  while (indexStart != -1) {
    if (indexStart == s.length - 1) break;

    int indexEnd = s.indexOf(Utils.specialRegex, indexStart + 1);
    if (indexEnd != -1) {
      arguments.add(s.substring(indexStart + 1, indexEnd));
      s = s.substring(indexEnd);
      indexStart = s.indexOf('\$');
    } else {
      arguments.add(s.substring(indexStart + 1));
      break;
    }
  }

  return arguments;
}
