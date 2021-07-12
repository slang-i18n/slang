import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/context_type.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:fast_i18n/src/model/pluralization.dart';
import 'package:fast_i18n/src/string_extensions.dart';

class NodeBuilder {
  static ObjectNode fromMap(BuildConfig config, Map<String, dynamic> map) {
    Map<String, Node> destination = Map();
    _parseMapNode(config, map, destination, []);
    return ObjectNode(destination, ObjectNodeType.classType, null);
  }

  static void _parseMapNode(
    BuildConfig config,
    Map<String, dynamic> curr,
    Map<String, Node> destination,
    List<String> stack,
  ) {
    curr.forEach((key, value) {
      key = key.toCase(config.keyCase);

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
          _parseMapNode(config, listAsMap, childrenTarget, nextStack);

          // finally only take their values, ignoring keys
          destination[key] = ListNode(childrenTarget.values.toList());
        } else {
          // key: { ...value }
          _parseMapNode(config, value, childrenTarget, nextStack);
          _DetectionResult result =
              _determineNodeType(config, nextStack, childrenTarget);

          if (result.nodeType == ObjectNodeType.context ||
              result.nodeType == ObjectNodeType.pluralCardinal ||
              result.nodeType == ObjectNodeType.pluralOrdinal) {
            // split children by comma
            final entries = childrenTarget.entries.toList();
            for (final entry in entries) {
              final split = entry.key.split(Node.KEY_DELIMITER);
              if (split.length != 1) {
                // {one,two: hi} -> {one: hi, two: hi}
                childrenTarget.remove(entry.key);
                for (final newChild in split) {
                  // all children have the same value
                  childrenTarget[newChild] = entry.value;
                }
              }
            }
          }

          destination[key] =
              ObjectNode(childrenTarget, result.nodeType, result.contextHint);
        }
      }
    });
  }

  static _DetectionResult _determineNodeType(
      BuildConfig config, List<String> stack, Map<String, Node> children) {
    String stackAsString = stack.join('.');
    if (config.maps.contains(stackAsString)) {
      return _DetectionResult(ObjectNodeType.map);
    } else if (config.pluralCardinal.contains(stackAsString)) {
      return _DetectionResult(ObjectNodeType.pluralCardinal);
    } else if (config.pluralOrdinal.contains(stackAsString)) {
      return _DetectionResult(ObjectNodeType.pluralOrdinal);
    } else {
      final childrenSplitByComma =
          children.keys.expand((key) => key.split(Node.KEY_DELIMITER)).toList();

      if (config.pluralAuto != PluralAuto.off) {
        // check if every children is 'zero', 'one', 'two', 'few', 'many' or 'other'
        final isPlural =
            childrenSplitByComma.length <= Quantity.values.length &&
                childrenSplitByComma.every(
                    (key) => Quantity.values.any((q) => q.paramName() == key));
        if (isPlural) {
          switch (config.pluralAuto) {
            case PluralAuto.cardinal:
              return _DetectionResult(ObjectNodeType.pluralCardinal);
            case PluralAuto.ordinal:
              return _DetectionResult(ObjectNodeType.pluralOrdinal);
            case PluralAuto.off:
              break;
          }
        }
      }

      for (final contextType in config.contexts) {
        if (contextType.auto) {
          final isContext = childrenSplitByComma.length ==
                  contextType.enumValues.length &&
              childrenSplitByComma
                  .every((key) => contextType.enumValues.any((e) => e == key));
          if (isContext) {
            return _DetectionResult(ObjectNodeType.context, contextType);
          }
        } else if (contextType.paths.contains(stackAsString)) {
          return _DetectionResult(ObjectNodeType.context, contextType);
        }
      }

      return _DetectionResult(ObjectNodeType.classType);
    }
  }
}

class _DetectionResult {
  final ObjectNodeType nodeType;
  final ContextType? contextHint;

  _DetectionResult(this.nodeType, [this.contextHint]);
}
