import 'dart:convert';

import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:fast_i18n/src/model/pluralization.dart';

/// parses a json of one locale
/// returns an I18nData object
I18nData parseJSON(BuildConfig config, I18nLocale locale, String content) {
  Map<String, dynamic> map = json.decode(content);
  Map<String, Node> destination = Map();
  _parseJSONNode(config, map, destination, []);

  return I18nData(
    base: config.baseLocale == locale,
    locale: locale,
    root: ObjectNode(destination, ObjectNodeType.classType),
  );
}

void _parseJSONNode(
  BuildConfig config,
  Map<String, dynamic> curr,
  Map<String, Node> destination,
  List<String> stack,
) {
  curr.forEach((key, value) {
    if (value is String) {
      // leaf
      // key: 'value'
      destination[key] = TextNode(value, config.stringInterpolation);
    } else {
      final List<String> nextStack = [...stack, key];
      final Map<String, Node> childrenTarget = Map();

      if (value is List) {
        // key: [ ...value ]
        // interpret the list as map
        final Map<String, dynamic> listAsMap = {
          for (int i = 0; i < value.length; i++) i.toString(): value[i],
        };
        _parseJSONNode(config, listAsMap, childrenTarget, nextStack);

        // finally only take their values, ignoring keys
        destination[key] = ListNode(childrenTarget.values.toList());
      } else {
        // key: { ...value }
        _parseJSONNode(config, value, childrenTarget, nextStack);
        ObjectNodeType nodeType =
            _determineNodeType(config, nextStack, childrenTarget);
        destination[key] = ObjectNode(childrenTarget, nodeType);
      }
    }
  });
}

ObjectNodeType _determineNodeType(
    BuildConfig config, List<String> stack, Map<String, Node> children) {
  String stackAsString = stack.join('.');
  if (config.maps.contains(stackAsString)) {
    return ObjectNodeType.map;
  } else if (config.pluralCardinal.contains(stackAsString)) {
    return ObjectNodeType.pluralCardinal;
  } else if (config.pluralOrdinal.contains(stackAsString)) {
    return ObjectNodeType.pluralOrdinal;
  } else {
    ObjectNodeType? autoPluralType;
    if (config.pluralAuto != PluralAuto.off) {
      // check if every children is 'zero', 'one', 'two', 'few', 'many' or 'other'
      final isPlural = children.keys.length <= Quantity.values.length &&
          children.keys
              .every((key) => Quantity.values.any((q) => q.paramName() == key));
      if (isPlural) {
        switch (config.pluralAuto) {
          case PluralAuto.cardinal:
            autoPluralType = ObjectNodeType.pluralCardinal;
            break;
          case PluralAuto.ordinal:
            autoPluralType = ObjectNodeType.pluralOrdinal;
            break;
          case PluralAuto.off:
        }
      }
    }

    return autoPluralType ?? ObjectNodeType.classType;
  }
}
