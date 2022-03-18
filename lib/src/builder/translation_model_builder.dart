import 'dart:collection';

import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/context_type.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/interface.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:fast_i18n/src/model/pluralization.dart';
import 'package:fast_i18n/src/utils/regex_utils.dart';
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
    bool hasCardinal = false;
    bool hasOrdinal = false;

    // flat map for leaves (TextNode, PluralNode, ContextNode)
    final Map<String, LeafNode> leavesMap = {};

    // 1st round: Build nodes according to given map
    //
    // Linked Translations:
    // They will be tracked but not handled
    // Assumption: They are basic linked translations without parameters
    // Reason: Not all TextNodes are built, so final parameters are unknown
    final resultNodeTree = _parseMapNode(
      parentPath: '',
      curr: map,
      config: buildConfig,
      keyCase: buildConfig.keyCase,
      leavesMap: leavesMap,
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
        final paramSet = <String>{};
        final visitedLinks = <String>{};
        final pathQueue = Queue<String>();
        pathQueue.add(link);

        while (pathQueue.isNotEmpty) {
          final currLink = pathQueue.removeFirst();
          final linkedNode = leavesMap[currLink];
          if (linkedNode == null) {
            throw '"$key" is linked to "$currLink" but it is undefined (locale: ${locale.languageTag}).';
          }

          visitedLinks.add(currLink);

          if (linkedNode is TextNode) {
            paramSet.addAll(linkedNode.params);

            // lookup links
            linkedNode.links.forEach((child) {
              if (!visitedLinks.contains(child)) {
                pathQueue.add(child);
              }
            });
          } else if (linkedNode is PluralNode || linkedNode is ContextNode) {
            final Iterable<TextNode> textNodes = linkedNode is PluralNode
                ? linkedNode.quantities.values
                : (linkedNode as ContextNode).entries.values;
            final linkedParamSet = textNodes
                .map((e) => e.params)
                .expand((params) => params)
                .toSet();

            if (linkedNode is PluralNode) {
              linkedParamSet.add(linkedNode.paramName);
              paramTypeMap[linkedNode.paramName] = 'num';
            } else if (linkedNode is ContextNode) {
              linkedParamSet.add(linkedNode.paramName);
              paramTypeMap[linkedNode.paramName] = linkedNode.context.enumName;
            }

            paramSet.addAll(linkedParamSet);

            // lookup links of children
            textNodes.forEach((element) {
              element.links.forEach((child) {
                if (!visitedLinks.contains(child)) {
                  pathQueue.add(child);
                }
              });
            });
          } else {
            throw '"$key" is linked to "$currLink" which is a ${linkedNode.runtimeType} (must be $TextNode or $ObjectNode).';
          }
        }

        linkParamMap[link] = paramSet;
      });

      if (linkParamMap.values.any((params) => params.isNotEmpty)) {
        // rebuild TextNode because its linked translations have parameters
        value.updateWithLinkParams(
          linkParamMap: linkParamMap,
          paramTypeMap: paramTypeMap,
        );
      }
    });

    // imaginary root node
    final root = ObjectNode(
      path: '',
      comment: null,
      entries: resultNodeTree,
      isMap: false,
    );

    // 3rd round: Add interfaces

    final List<Interface> resultInterfaces;
    if (buildConfig.interfaces.isEmpty) {
      resultInterfaces = [];
    } else {
      // Interfaces with no specified path
      // will be applied globally
      Set<Interface> globalInterfaces = {};

      // Interface Name -> Interface
      // This may be smaller than [pathInterfaceNameMap] because the user may
      // specify an interface without attributes - in this case the interface
      // will be determined.
      Map<String, Interface> nameInterfaceMap = {};

      // Path -> Interface Name
      Map<String, String> pathInterfaceContainerMap = {};

      // Path -> Interface Name
      Map<String, String> pathInterfaceNameMap = {};

      // add from build config
      buildConfig.interfaces.forEach((interfaceConfig) {
        final Interface? interface;
        if (interfaceConfig.attributes.isNotEmpty) {
          interface = interfaceConfig.toInterface();
          nameInterfaceMap[interface.name] = interface;
        } else {
          interface = null;
        }

        if (interfaceConfig.paths.isEmpty && interface != null) {
          globalInterfaces.add(interface);
        } else {
          interfaceConfig.paths.forEach((path) {
            if (path.isContainer) {
              pathInterfaceContainerMap[path.path] = interfaceConfig.name;
            } else {
              pathInterfaceNameMap[path.path] = interfaceConfig.name;
            }
          });
        }
      });

      resultInterfaces = _applyInterfaceAndGenericsRecursive(
        curr: root,
        globalInterfaces: globalInterfaces,
        nameInterfaceMap: nameInterfaceMap,
        pathInterfaceContainerNameMap: pathInterfaceContainerMap,
        pathInterfaceNameMap: pathInterfaceNameMap,
      ).toList();
    }

    return I18nData(
      base: buildConfig.baseLocale == locale,
      locale: locale,
      root: root,
      interfaces: resultInterfaces,
      hasCardinal: hasCardinal,
      hasOrdinal: hasOrdinal,
    );
  }

  /// Takes the [curr] map which is (a part of) the raw tree from json / yaml
  /// and returns the node model.
  static Map<String, Node> _parseMapNode({
    required String parentPath,
    required Map<String, dynamic> curr,
    required BuildConfig config,
    required CaseStyle? keyCase,
    required Map<String, LeafNode> leavesMap,
    required Function cardinalNotifier,
    required Function ordinalNotifier,
  }) {
    final Map<String, Node> resultNodeTree = {};

    curr.forEach((key, value) {
      if (key.startsWith('@')) {
        // ignore comments
        return;
      }

      final originalKey = key;

      // transform key if necessary
      // the part after '(' is considered as the parameter hint for plurals or contexts
      key = key.split('(').first.toCase(keyCase);
      final currPath = parentPath.isNotEmpty ? '$parentPath.$key' : key;

      // parse comment
      final String? comment;
      final dynamic commentObj = curr['@$key'];
      if (commentObj != null) {
        // comment node exists
        if (commentObj is String) {
          // parse string directly
          comment = commentObj;
        } else if (commentObj is Map<String, dynamic>) {
          // ARB style
          comment = commentObj['description']?.toString();
        } else {
          comment = null;
        }
      } else {
        comment = null;
      }

      if (value is String || value is num) {
        // leaf
        // key: 'value'
        final textNode = TextNode(
          path: currPath,
          raw: value.toString(),
          comment: comment,
          interpolation: config.stringInterpolation,
          paramCase: config.paramCase,
        );
        resultNodeTree[key] = textNode;
        leavesMap[currPath] = textNode;
      } else {
        final Map<String, Node> children;

        if (value is List) {
          // key: [ ...value ]
          // interpret the list as map
          final Map<String, dynamic> listAsMap = {
            for (int i = 0; i < value.length; i++) i.toString(): value[i],
          };
          children = _parseMapNode(
            parentPath: currPath,
            curr: listAsMap,
            config: config,
            keyCase: config.keyCase,
            leavesMap: leavesMap,
            cardinalNotifier: cardinalNotifier,
            ordinalNotifier: ordinalNotifier,
          );

          // finally only take their values, ignoring keys
          final node = ListNode(
            path: currPath,
            comment: comment,
            entries: children.values.toList(),
          );
          _setParent(node, children.values);
          resultNodeTree[key] = node;
        } else {
          // key: { ...value }
          final children = _parseMapNode(
            parentPath: currPath,
            curr: value,
            config: config,
            keyCase: config.keyCase != config.keyMapCase &&
                    config.maps.contains(currPath)
                ? config.keyMapCase
                : config.keyCase,
            leavesMap: leavesMap,
            cardinalNotifier: cardinalNotifier,
            ordinalNotifier: ordinalNotifier,
          );

          Node node;
          _DetectionResult detectedType =
              _determineNodeType(config, currPath, children);

          // notify plural and split by comma if necessary
          if (detectedType.nodeType == _DetectionType.context ||
              detectedType.nodeType == _DetectionType.pluralCardinal ||
              detectedType.nodeType == _DetectionType.pluralOrdinal) {
            if (detectedType.nodeType == _DetectionType.pluralCardinal) {
              cardinalNotifier();
            } else if (detectedType.nodeType == _DetectionType.pluralOrdinal) {
              ordinalNotifier();
            }

            // split children by comma for plurals and contexts
            final digestedMap = <String, TextNode>{};
            final entries = children.entries.toList();
            for (final entry in entries) {
              final split = entry.key.split(Node.KEY_DELIMITER);
              if (split.length == 1) {
                // keep as is
                digestedMap[entry.key] = entry.value as TextNode;
              } else {
                // split!
                // {one,two: hi} -> {one: hi, two: hi}
                for (final newChild in split) {
                  digestedMap[newChild] = entry.value as TextNode;
                }
              }
            }

            final String? paramNameHint =
                RegexUtils.paramHintRegex.firstMatch(originalKey)?.group(1);
            if (detectedType.nodeType == _DetectionType.context) {
              node = ContextNode(
                path: currPath,
                comment: comment,
                context: detectedType.contextHint!,
                entries: digestedMap,
                parameterName: paramNameHint,
              );
            } else {
              node = PluralNode(
                path: currPath,
                comment: comment,
                pluralType:
                    detectedType.nodeType == _DetectionType.pluralCardinal
                        ? PluralType.cardinal
                        : PluralType.ordinal,
                quantities: digestedMap.map((key, value) {
                  // assume that parsing to quantity never fails (hence, never null)
                  // because detection was correct
                  return MapEntry(key.toQuantity()!, value);
                }),
                parameterName: paramNameHint,
              );
            }
          } else {
            node = ObjectNode(
              path: currPath,
              comment: comment,
              entries: children,
              isMap: detectedType.nodeType == _DetectionType.map,
            );
          }

          _setParent(node, children.values);
          resultNodeTree[key] = node;
          if (node is PluralNode || node is ContextNode) {
            leavesMap[currPath] = node as LeafNode;
          }
        }
      }
    });

    return resultNodeTree;
  }

  static void _setParent(Node parent, Iterable<Node> children) {
    children.forEach((child) => child.setParent(parent));
  }

  static _DetectionResult _determineNodeType(
    BuildConfig config,
    String nodePath,
    Map<String, Node> children,
  ) {
    if (config.maps.contains(nodePath)) {
      return _DetectionResult(_DetectionType.map);
    } else if (config.pluralCardinal.contains(nodePath)) {
      return _DetectionResult(_DetectionType.pluralCardinal);
    } else if (config.pluralOrdinal.contains(nodePath)) {
      return _DetectionResult(_DetectionType.pluralOrdinal);
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
              return _DetectionResult(_DetectionType.pluralCardinal);
            case PluralAuto.ordinal:
              return _DetectionResult(_DetectionType.pluralOrdinal);
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
            return _DetectionResult(_DetectionType.context, contextType);
          }
        } else if (contextType.paths.contains(nodePath)) {
          return _DetectionResult(_DetectionType.context, contextType);
        }
      }

      // fallback: every node is a class by default
      return _DetectionResult(_DetectionType.classType);
    }
  }

  /// Traverses the tree in post order and finds interfaces
  /// Sets interface and genericType for the affected nodes
  /// Returns the resulting interface list
  static Iterable<Interface> _applyInterfaceAndGenericsRecursive({
    required IterableNode curr,
    required Set<Interface> globalInterfaces,
    required Map<String, Interface> nameInterfaceMap,
    required Map<String, String> pathInterfaceContainerNameMap,
    required Map<String, String> pathInterfaceNameMap,
  }) {
    final Iterable<Node> children;

    if (curr is ListNode) {
      children = curr.entries;
    } else if (curr is ObjectNode) {
      children = curr.entries.values;
    } else {
      throw 'This should not happen';
    }

    // first calculate for children (post order!)
    children.forEach((child) {
      if (child is IterableNode) {
        _applyInterfaceAndGenericsRecursive(
          curr: child,
          globalInterfaces: globalInterfaces,
          nameInterfaceMap: nameInterfaceMap,
          pathInterfaceContainerNameMap: pathInterfaceContainerNameMap,
          pathInterfaceNameMap: pathInterfaceNameMap,
        );
      }
    });

    if (curr is ObjectNode) {
      // check if this node itself is an interface
      final interface = _determineInterface(
        node: curr,
        globalInterfaces: globalInterfaces,
        nameInterfaceMap: nameInterfaceMap,
        pathInterfaceNameMap: pathInterfaceNameMap,
      );
      if (interface != null) {
        curr.setInterface(interface);

        // in case this interface is new
        nameInterfaceMap[interface.name] = interface;
      }
    }

    final containerInterface = _determineInterfaceForContainer(
      node: curr,
      globalInterfaces: globalInterfaces,
      nameInterfaceMap: nameInterfaceMap,
      pathInterfaceContainerNameMap: pathInterfaceContainerNameMap,
    );
    if (containerInterface != null) {
      curr.setGenericType(containerInterface.name);
      children
          .cast<ObjectNode>()
          .forEach((child) => child.setInterface(containerInterface));

      // in case this interface is new
      nameInterfaceMap[containerInterface.name] = containerInterface;
    }

    return nameInterfaceMap.values;
  }

  /// Returns the interface of the list or object node.
  /// No side effects.
  ///
  /// [node] this node
  /// [globalInterfaces] interfaces with attributes specified in build conf
  /// [nameInterfaceMap] Interface Name -> Interface, may grow if interfaces with unknown attributes get resolved
  /// [pathInterfaceContainerNameMap] Path -> Interface Name, as in build conf
  static Interface? _determineInterfaceForContainer({
    required IterableNode node,
    required Set<Interface> globalInterfaces,
    required Map<String, Interface> nameInterfaceMap,
    required Map<String, String> pathInterfaceContainerNameMap,
  }) {
    final List<ObjectNode> children;
    if (node is ListNode) {
      if (node.entries.every((child) => child is ObjectNode)) {
        children = node.entries.cast<ObjectNode>().toList();
      } else {
        return null;
      }
    } else {
      if ((node as ObjectNode)
          .entries
          .values
          .every((child) => child is ObjectNode)) {
        children = node.entries.values.cast<ObjectNode>().toList();
      } else {
        return null;
      }
    }

    // first check if the path is specified to be an interface (via build config)
    final specifiedInterface = pathInterfaceContainerNameMap[node.path];
    if (specifiedInterface != null) {
      final existingInterface = nameInterfaceMap[specifiedInterface];
      if (existingInterface != null) {
        // user has specified path and attributes for this interface
        return existingInterface;
      }
    }

    // find minimum attribute set all object nodes have in common
    // and a super set containing all attributes of all object nodes
    final commonAttributes = _parseAttributes(children.first);
    final allAttributes = {...commonAttributes};
    children.skip(1).forEach((child) {
      final currAttributes = _parseAttributes(child);
      allAttributes.addAll(currAttributes);
      commonAttributes
          .removeWhere((attribute) => !currAttributes.contains(attribute));
    });
    final optionalAttributes = allAttributes
        .difference(commonAttributes)
        .map((attribute) => InterfaceAttribute(
              attributeName: attribute.attributeName,
              returnType: attribute.returnType,
              parameters: attribute.parameters,
              optional: true,
            ))
        .toSet();

    if (specifiedInterface != null) {
      // user has specified the path but not the concrete attributes
      // create the corresponding concrete interface here
      return Interface(
        name: specifiedInterface,
        attributes: {...commonAttributes, ...optionalAttributes},
      );
    } else {
      // lets find the first interface that satisfy this hypothetical interface
      // only one interface is allowed because generics do not allow unions
      final potentialInterface = globalInterfaces.cast<Interface?>().firstWhere(
            (interface) => Interface.satisfyRequiredSet(
                requiredSet: interface!.attributes, testSet: commonAttributes),
            orElse: () => null,
          );
      return potentialInterface;
    }
  }

  /// Returns the interface of the object node.
  /// No side effects.
  ///
  /// [node] this node
  /// [globalInterfaces] interfaces with attributes specified in build conf
  /// [nameInterfaceMap] Interface Name -> Interface, may grow if interfaces with unknown attributes get resolved
  /// [pathInterfaceNameMap] Path -> Interface Name, as in build conf
  static Interface? _determineInterface({
    required ObjectNode node,
    required Set<Interface> globalInterfaces,
    required Map<String, Interface> nameInterfaceMap,
    required Map<String, String> pathInterfaceNameMap,
  }) {
    // first check if the path is specified to be an interface (via build config)
    final specifiedInterface = pathInterfaceNameMap[node.path];
    if (specifiedInterface != null) {
      final existingInterface = nameInterfaceMap[specifiedInterface];
      if (existingInterface != null) {
        // user has specified path and attributes for this interface
        return existingInterface;
      }
    }

    // find attributes
    final attributes = _parseAttributes(node);

    if (specifiedInterface != null) {
      // user has specified the path but not the concrete attributes
      // create the corresponding concrete interface here
      return Interface(
        name: specifiedInterface,
        attributes: attributes,
      );
    } else {
      // lets find the first interface that satisfy this hypothetical interface
      // only one interface is allowed because generics do not allow unions
      final potentialInterface = globalInterfaces.cast<Interface?>().firstWhere(
            (interface) => Interface.satisfyRequiredSet(
                requiredSet: interface!.attributes, testSet: attributes),
            orElse: () => null,
          );
      return potentialInterface;
    }
  }

  /// Finds the attributes of the object node.
  /// No side effects.
  static Set<InterfaceAttribute> _parseAttributes(ObjectNode node) {
    return node.entries.entries.map((entry) {
      final child = entry.value;
      String returnType;
      Set<AttributeParameter> parameters;
      if (child is TextNode) {
        returnType = 'String';
        parameters = child.params.map((p) {
          return AttributeParameter(
            parameterName: p,
            type: child.paramTypeMap[p] ?? 'Object',
          );
        }).toSet();
      } else if (child is ListNode) {
        parameters = {}; // lists never have parameters
        returnType = 'List<${child.genericType}>';
      } else if (child is ObjectNode) {
        parameters = {}; // objects never have parameters
        returnType = 'Map<String, ${child.genericType}>';
      } else if (child is PluralNode) {
        parameters = {
          AttributeParameter(parameterName: child.paramName, type: 'num'),
          ...child.quantities.values
              .cast<TextNode>()
              .map((text) => text.params)
              .expand((param) => param)
              .where((param) => param != child.paramName)
              .map((param) =>
                  AttributeParameter(parameterName: param, type: 'Object'))
        };
        returnType = 'String';
      } else if (child is ContextNode) {
        parameters = {
          AttributeParameter(
              parameterName: child.paramName, type: child.context.enumName),
          ...child.entries.values
              .cast<TextNode>()
              .map((text) => text.params)
              .expand((param) => param)
              .where((param) => param != child.paramName)
              .map((param) =>
                  AttributeParameter(parameterName: param, type: 'Object'))
        };
        returnType = 'String';
      } else {
        throw 'This should not happen';
      }
      return InterfaceAttribute(
        attributeName: entry.key,
        returnType: returnType,
        parameters: parameters,
        optional: false,
      );
    }).toSet();
  }
}

enum _DetectionType {
  classType,
  map,
  pluralCardinal,
  pluralOrdinal,
  context,
}

class _DetectionResult {
  final _DetectionType nodeType;
  final ContextType? contextHint;

  _DetectionResult(this.nodeType, [this.contextHint]);
}
