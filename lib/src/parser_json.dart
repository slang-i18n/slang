import 'dart:convert';

import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/node.dart';

/// parses a json of one locale
/// returns an I18nData object
I18nData parseJSON(BuildConfig config, I18nLocale locale, String content) {
  Map<String, dynamic> map = json.decode(content);
  Map<String, Node> destination = Map();
  _parseJSONObject(config, map, destination, []);

  return I18nData(
    base: config.baseLocale == locale,
    locale: locale,
    root: ObjectNode(destination, ObjectNodeType.classType),
  );
}

/// parses one json object { a : b }
/// writes result to [destination]
/// each new layer will be put into the [stack], e.g. [welcome, title] would be { welcome { title: Hello } }
void _parseJSONObject(
  BuildConfig config,
  Map<String, dynamic> curr,
  Map<String, Node> destination,
  List<String> stack,
) {
  curr.forEach((key, value) {
    if (value is String) {
      // key: 'value'
      destination[key] = TextNode(value, config.stringInterpolation);
    } else if (value is List) {
      // key: [ ...value ]
      List<Node> list = List.empty(growable: true);
      _parseJSONArray(config, value, list, stack);
      destination[key] = ListNode(list);
    } else {
      // key: { ...value }
      List<String> nextStack = [...stack, key];
      String stackAsString = nextStack.join('.');
      ObjectNodeType nodeType;
      if (config.maps.contains(stackAsString))
        nodeType = ObjectNodeType.map;
      else if (config.pluralCardinal.contains(stackAsString))
        nodeType = ObjectNodeType.pluralCardinal;
      else if (config.pluralOrdinal.contains(stackAsString))
        nodeType = ObjectNodeType.pluralOrdinal;
      else
        nodeType = ObjectNodeType.classType;
      Map<String, Node> subDestination = Map();
      _parseJSONObject(config, value, subDestination, nextStack);
      destination[key] = ObjectNode(subDestination, nodeType);
    }
  });
}

/// parses one json list [a, b, c]
/// writes result to [destination]
void _parseJSONArray(
  BuildConfig config,
  List<dynamic> curr,
  List<Node> destination,
  List<String> stack,
) {
  for (dynamic value in curr) {
    if (value is String) {
      // key: 'value'
      destination.add(TextNode(value, config.stringInterpolation));
    } else if (value is List) {
      // key: [ ...value ]
      List<Node> list = List.empty(growable: true);
      _parseJSONArray(config, value, list, stack);
      destination.add(ListNode(list));
    } else {
      // key: { ...value }
      String stackAsString = stack.join('.');
      ObjectNodeType nodeType;
      if (config.maps.contains(stackAsString))
        nodeType = ObjectNodeType.map;
      else if (config.pluralCardinal.contains(stackAsString))
        nodeType = ObjectNodeType.pluralCardinal;
      else if (config.pluralOrdinal.contains(stackAsString))
        nodeType = ObjectNodeType.pluralOrdinal;
      else
        nodeType = ObjectNodeType.classType;
      Map<String, Node> subDestination = Map();
      _parseJSONObject(config, value, subDestination, stack);
      destination.add(ObjectNode(subDestination, nodeType));
    }
  }
}
