import 'dart:collection';

import 'package:fast_i18n/src/generator/generate_translations.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/context_type.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/interface.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:fast_i18n/src/model/pluralization.dart';
import 'package:fast_i18n/src/utils/string_extensions.dart';

class TranslationModelBuilder {
  /// Builds the i18n model for ONE locale
  ///
  /// The map must be of type Map<String, dynamic> and all children may of type
  /// String, num, List<dynamic> or Map<String, dynamic>.
  static I18nData build({
    required BuildConfig buildConfig,
    required I18nLocale locale,
    required Map<String, dynamic> map,
  }) {
    final localeEnum = '${buildConfig.enumName}.${locale.enumConstant}';
    bool hasCardinal = false;
    bool hasOrdinal = false;

    // flat map for leaves, i.e. a) TextNode or b) ObjectNode of type context or plural
    final Map<String, Node> leavesMap = {};

    // 1st round: Build nodes according to given map
    //
    // Linked Translations:
    // They will be tracked but not handled
    // Assumption: They are basic linked translations without parameters
    // Reason: Not all TextNodes are built, so final parameters are unknown
    final resultNodeTree = _parseMapNode(
      curr: map,
      config: buildConfig,
      keyCase: buildConfig.keyCase,
      localeEnum: localeEnum,
      leavesMap: leavesMap,
      stack: [],
      cardinalNotifier: () {
        hasCardinal = true;
      },
      ordinalNotifier: () {
        hasOrdinal = true;
      },
    );

    // 2nd round: Handle parameterized linked translations
    //
    // TextNodes with parameterized linked translations are rebuilt with correct parameters.
    leavesMap.entries
        .where((entry) => entry.value is TextNode)
        .forEach((entry) {
      final key = entry.key;
      final value = entry.value as TextNode;

      final linkParamMap = <String, Set<String>>{};
      final paramTypeMap = <String, String>{};
      value.links.forEach((link) {
        final currParam = <String>{};
        final visitedLinks = <String>{};
        final queue = Queue<String>();
        queue.add(link);

        while (queue.isNotEmpty) {
          final currLink = queue.removeFirst();
          final linkedNode = leavesMap[currLink];
          if (linkedNode == null) {
            throw '"$key" is linked to "$currLink" but it is undefined (${locale.languageTag}).';
          }

          visitedLinks.add(currLink);

          if (linkedNode is TextNode) {
            currParam.addAll(linkedNode.params);

            // lookup links
            linkedNode.links.forEach((child) {
              if (!visitedLinks.contains(child)) {
                queue.add(child);
              }
            });
          } else if (linkedNode is ObjectNode) {
            final paramSet = linkedNode.entries.values
                .map((e) => (e as TextNode).params)
                .expand((params) => params)
                .toSet();
            if (linkedNode.type == ObjectNodeType.context) {
              paramSet.add(CONTEXT_PARAMETER);
              paramTypeMap[CONTEXT_PARAMETER] =
                  linkedNode.contextHint!.enumName;
            } else {
              paramSet.add(PLURAL_PARAMETER);
              paramTypeMap[PLURAL_PARAMETER] = 'num';
            }
            currParam.addAll(paramSet);

            // lookup links of children
            linkedNode.entries.values.forEach((element) {
              (element as TextNode).links.forEach((child) {
                if (!visitedLinks.contains(child)) {
                  queue.add(child);
                }
              });
            });
          } else {
            throw '"$key" is linked to "$currLink" which is a ${linkedNode.runtimeType} (must be $TextNode or $ObjectNode).';
          }
        }

        linkParamMap[link] = currParam;
      });

      if (linkParamMap.values.any((params) => params.isNotEmpty)) {
        // rebuild TextNode because its linked translations have parameters
        final textNode = TextNode(value.raw, buildConfig.stringInterpolation,
            localeEnum, buildConfig.paramCase, linkParamMap);
        value.params = textNode.params;
        value.content = textNode.content;
        value.paramTypeMap = paramTypeMap;
      }
    });

    // 3rd round: Add interfaces
    List<Interface> interfaces = [];

    return I18nData(
      base: buildConfig.baseLocale == locale,
      locale: locale,
      root: ObjectNode(
        parent: null,
        entries: resultNodeTree,
        type: ObjectNodeType.classType,
        contextHint: null,
      ),
      interfaces: interfaces,
      hasCardinal: hasCardinal,
      hasOrdinal: hasOrdinal,
    );
  }

  /// Takes the [curr] map which is (a part of) the raw tree from json / yaml
  /// and returns the node model.
  static Map<String, Node> _parseMapNode({
    required Map<String, dynamic> curr,
    required BuildConfig config,
    required CaseStyle? keyCase,
    required String localeEnum,
    required Map<String, Node> leavesMap,
    required List<String> stack,
    required Function cardinalNotifier,
    required Function ordinalNotifier,
  }) {
    final Map<String, Node> resultNodeTree = {};

    curr.forEach((key, value) {
      key = key.toCase(keyCase); // transform key if necessary

      if (value is String || value is num) {
        // leaf
        // key: 'value'
        final textNode = TextNode(
          value.toString(),
          config.stringInterpolation,
          localeEnum,
          config.paramCase,
        );
        resultNodeTree[key] = textNode;
        leavesMap[[...stack, key].toNodePath()] = textNode;
      } else {
        final List<String> nextStack = [...stack, key];
        final Map<String, Node> children;

        if (value is List) {
          // key: [ ...value ]
          // interpret the list as map
          final Map<String, dynamic> listAsMap = {
            for (int i = 0; i < value.length; i++) i.toString(): value[i],
          };
          children = _parseMapNode(
            curr: listAsMap,
            config: config,
            keyCase: config.keyCase,
            localeEnum: localeEnum,
            leavesMap: leavesMap,
            stack: nextStack,
            cardinalNotifier: cardinalNotifier,
            ordinalNotifier: ordinalNotifier,
          );

          // finally only take their values, ignoring keys
          resultNodeTree[key] = ListNode(children.values.toList());
        } else {
          // key: { ...value }
          children = _parseMapNode(
            curr: value,
            config: config,
            keyCase: config.keyCase != config.keyMapCase &&
                    _determineMapType(config, nextStack)
                ? config.keyMapCase
                : config.keyCase,
            localeEnum: localeEnum,
            leavesMap: leavesMap,
            stack: nextStack,
            cardinalNotifier: cardinalNotifier,
            ordinalNotifier: ordinalNotifier,
          );
          _DetectionResult detectedType =
              _determineNodeType(config, nextStack, children);

          // notify plural and split by comma if necessary
          if (detectedType.nodeType == ObjectNodeType.context ||
              detectedType.nodeType == ObjectNodeType.pluralCardinal ||
              detectedType.nodeType == ObjectNodeType.pluralOrdinal) {
            if (detectedType.nodeType == ObjectNodeType.pluralCardinal) {
              cardinalNotifier();
            } else if (detectedType.nodeType == ObjectNodeType.pluralOrdinal) {
              ordinalNotifier();
            }

            // split children by comma
            final entries = children.entries.toList();
            for (final entry in entries) {
              final split = entry.key.split(Node.KEY_DELIMITER);
              if (split.length != 1) {
                // {one,two: hi} -> {one: hi, two: hi}
                children.remove(entry.key);
                for (final newChild in split) {
                  // all children have the same value
                  children[newChild] = entry.value;
                }
              }
            }
          }

          final node = ObjectNode(
            parent: null,
            entries: children,
            type: detectedType.nodeType,
            contextHint: detectedType.contextHint,
          );
          resultNodeTree[key] = node;
          if (node.type == ObjectNodeType.pluralCardinal ||
              node.type == ObjectNodeType.pluralOrdinal ||
              node.type == ObjectNodeType.context) {
            leavesMap[nextStack.toNodePath()] = node;
          }
        }
      }
    });

    return resultNodeTree;
  }

  static _DetectionResult _determineNodeType(
      BuildConfig config, List<String> stack, Map<String, Node> children) {
    String nodePath = stack.toNodePath();
    if (config.maps.contains(nodePath)) {
      return _DetectionResult(ObjectNodeType.map);
    } else if (config.pluralCardinal.contains(nodePath)) {
      return _DetectionResult(ObjectNodeType.pluralCardinal);
    } else if (config.pluralOrdinal.contains(nodePath)) {
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
        } else if (contextType.paths.contains(nodePath)) {
          return _DetectionResult(ObjectNodeType.context, contextType);
        }
      }

      return _DetectionResult(ObjectNodeType.classType);
    }
  }

  /// light version of [_determineNodeType] only checking map type
  static bool _determineMapType(BuildConfig config, List<String> stack) {
    return config.maps.contains(stack.toNodePath());
  }
}

class _DetectionResult {
  final ObjectNodeType nodeType;
  final ContextType? contextHint;

  _DetectionResult(this.nodeType, [this.contextHint]);
}

extension on List<String> {
  String toNodePath() {
    return this.join('.');
  }
}
