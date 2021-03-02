import 'package:fast_i18n/utils.dart';

/// general config, applies to all locales
class I18nConfig {
  final String baseName; // name of all i18n files, like strings or messages
  final String baseLocale; // defaults to 'en'
  final List<String> maps; // list of entities treated as maps and not classes
  final String keyCase;
  final String translateVariable;

  I18nConfig({
    this.baseName,
    this.baseLocale,
    this.maps,
    this.keyCase,
    this.translateVariable,
  });

  @override
  String toString() => '$baseLocale, maps: $maps';
}

/// represents one locale and its localized strings
class I18nData {
  final bool base; // whether or not this is the base locale
  final String locale; // the locale code (the part after the underscore)
  final ObjectNode root; // the actual strings

  I18nData({this.base, this.locale, this.root});
}

/// the super class of every node
class Value {}

class ObjectNode extends Value {
  final Map<String, Value> entries;
  final bool mapMode;
  final bool plainStrings;

  ObjectNode(this.entries, this.mapMode)
      : plainStrings = entries.values
            .every((child) => child is TextNode && child.params.isEmpty);

  @override
  String toString() => entries.toString();
}

class ListNode extends Value {
  final List<Value> entries;
  final bool plainStrings;

  ListNode(this.entries)
      : plainStrings =
            entries.every((child) => child is TextNode && child.params.isEmpty);

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
/// 'my name is ${name} and I am ${age} years old' => ['name', 'age']
List<String> _findArguments(String content) {
  return Utils.argumentsRegex
      .allMatches(content)
      .map((e) => e.group(2))
      .toList();
}
