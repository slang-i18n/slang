import 'dart:convert';

import 'package:fast_i18n/src/model.dart';

I18nData parseJSON(String baseName, String locale, String content) {
  Map<String, dynamic> map = json.decode(content);
  Map<String, Value> destination = Map();
  _parseJSON(map, destination);
  return I18nData(baseName, locale, destination);
}

void _parseJSON(Map<String, dynamic> curr, Map<String, Value> destination) {
  curr.forEach((key, value) {
    if (value is String) {
      destination[key] = Text(value);
    } else {
      Map<String, Value> subDestination = Map();
      destination[key] = ChildNode(subDestination);
      _parseJSON(value, subDestination);
    }
  });
}
