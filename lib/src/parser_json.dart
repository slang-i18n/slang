import 'dart:convert';

import 'package:fast_i18n/src/model.dart';

I18nData parseJSON(String baseName, String locale, String content) {
  Map<String, dynamic> map = json.decode(content);
  Map<String, Value> destination = Map();
  _parseJSONObject(map, destination);
  return I18nData(baseName, locale, ObjectNode(destination));
}

void _parseJSONObject(
    Map<String, dynamic> curr, Map<String, Value> destination) {
  curr.forEach((key, value) {
    if (value is String) {
      // key: 'value'
      destination[key] = TextNode(value);
    } else if (value is List) {
      // key: [ ...value ]
      List<Value> list = List();
      _parseJSONArray(value, list);
      destination[key] = ListNode(list);
    } else {
      // key: { ...value }
      Map<String, Value> subDestination = Map();
      _parseJSONObject(value, subDestination);
      destination[key] = ObjectNode(subDestination);
    }
  });
}

void _parseJSONArray(List<dynamic> curr, List<Value> destination) {
  for (dynamic value in curr) {
    if (value is String) {
      // key: 'value'
      destination.add(TextNode(value));
    } else if (value is List) {
      // key: [ ...value ]
      List<Value> list = List();
      destination.add(ListNode(list));
      _parseJSONArray(value, list);
    } else {
      // key: { ...value }
      Map<String, Value> subDestination = Map();
      destination.add(ObjectNode(subDestination));
      _parseJSONObject(value, subDestination);
    }
  }
}
