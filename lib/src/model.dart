import 'package:fast_i18n/utils.dart';

enum TranslationClassVisibility { private, public }
enum KeyCase { camel, pascal, snake }

extension EnumParser on String? {
  TranslationClassVisibility? toTranslationClassVisibility() {
    switch (this) {
      case 'private':
        return TranslationClassVisibility.private;
      case 'public':
        return TranslationClassVisibility.public;
      default:
        return null;
    }
  }

  KeyCase? toKeyCase() {
    switch (this) {
      case 'camel':
        return KeyCase.camel;
      case 'snake':
        return KeyCase.snake;
      case 'pascal':
        return KeyCase.pascal;
      default:
        return null;
    }
  }
}

/// general config, applies to all locales
class I18nConfig {
  final String baseName; // name of all i18n files, like strings or messages
  final String baseLocale; // defaults to 'en'
  final List<String> maps; // list of entities treated as maps and not classes
  final KeyCase? keyCase;
  final String translateVariable;
  final String enumName;
  final TranslationClassVisibility translationClassVisibility;

  I18nConfig(
      {required this.baseName,
      required this.baseLocale,
      required this.maps,
      required this.keyCase,
      required this.translateVariable,
      required this.enumName,
      required this.translationClassVisibility});

  @override
  String toString() => '$baseLocale, maps: $maps';
}

/// represents one locale and its localized strings
class I18nData {
  final bool base; // whether or not this is the base locale
  final String locale; // the locale code (the part after the underscore)
  final I18nLocale localeTyped; // the parsed locale code
  final ObjectNode root; // the actual strings

  I18nData({required this.base, required this.locale, required this.root})
      : localeTyped = _toI18nLocale(locale);
}

/// own Locale type to decouple from dart:ui package
class I18nLocale {
  final String language;
  final String? script;
  final String? country;

  I18nLocale({required this.language, this.script, this.country});
}

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

I18nLocale _toI18nLocale(String localeRaw) {
  final match = Utils.fileWithLocaleRegex.firstMatch(localeRaw);
  if (match != null) {
    final language = match.group(3);
    final script = match.group(5);
    final country = match.group(7);
    return I18nLocale(language: language ?? '', script: script, country: country);
  }
  return I18nLocale(language: localeRaw);
}
