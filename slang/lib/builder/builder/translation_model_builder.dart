import 'dart:collection';

import 'package:slang/builder/model/build_model_config.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/context_type.dart';
import 'package:slang/builder/model/interface.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/model/pluralization.dart';
import 'package:slang/builder/utils/regex_utils.dart';
import 'package:slang/builder/utils/string_extensions.dart';

class BuildModelResult {
  final ObjectNode root; // the actual strings
  final List<Interface> interfaces; // detected interfaces

  BuildModelResult({required this.root, required this.interfaces});
}

class TranslationModelBuilder {
  /// Builds the i18n model for ONE locale
  ///
  /// The map must be of type Map<String, dynamic> and all children may of type
  /// String, num, List<dynamic> or Map<String, dynamic>.
  static BuildModelResult build({
    required BuildModelConfig buildConfig,
    required Map<String, dynamic> map,
    required String localeDebug,
  }) {
    // flat map for leaves (TextNode, PluralNode, ContextNode)
    final Map<String, LeafNode> leavesMap = {};

    // 1st round: Build nodes according to given map
    //
    // Linked Translations:
    // They will be tracked but not handled
    // Assumption: They are basic linked translations without parameters
    // Reason: Not all TextNodes are built, so final parameters are unknown
    final resultNodeTree = _parseMapNode(
      localeDebug: localeDebug,
      parentPath: '',
      curr: map,
      config: buildConfig,
      keyCase: buildConfig.keyCase,
      leavesMap: leavesMap,
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
            throw '"$key" is linked to "$currLink" but "$currLink" is undefined (locale: $localeDebug).';
          }

          visitedLinks.add(currLink);

          if (linkedNode is TextNode) {
            paramSet.addAll(linkedNode.params);
            paramTypeMap.addAll(linkedNode.paramTypeMap);

            // lookup links
            linkedNode.links.forEach((child) {
              if (!visitedLinks.contains(child)) {
                pathQueue.add(child);
              }
            });
          } else if (linkedNode is PluralNode || linkedNode is ContextNode) {
            final Iterable<StringTextNode> textNodes = linkedNode is PluralNode
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
      resultInterfaces = _applyInterfaceAndGenericsRecursive(
        curr: root,
        interfaceCollection: buildConfig.buildInterfaceCollection(),
      ).toList();
    }

    return BuildModelResult(
      root: root,
      interfaces: resultInterfaces,
    );
  }

  /// Takes the [curr] map which is (a part of) the raw tree from json / yaml
  /// and returns the node model.
  static Map<String, Node> _parseMapNode({
    required String localeDebug,
    required String parentPath,
    required Map<String, dynamic> curr,
    required BuildModelConfig config,
    required CaseStyle? keyCase,
    required Map<String, LeafNode> leavesMap,
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
        final textNode = originalKey.endsWith('(rich)')
            ? RichTextNode(
                path: currPath,
                raw: value.toString(),
                comment: comment,
                interpolation: config.stringInterpolation,
                paramCase: config.paramCase,
              )
            : StringTextNode(
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
            localeDebug: localeDebug,
            parentPath: currPath,
            curr: listAsMap,
            config: config,
            keyCase: config.keyCase,
            leavesMap: leavesMap,
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
            localeDebug: localeDebug,
            parentPath: currPath,
            curr: value,
            config: config,
            keyCase: config.keyCase != config.keyMapCase &&
                    config.maps.contains(currPath)
                ? config.keyMapCase
                : config.keyCase,
            leavesMap: leavesMap,
          );

          Node node;
          _DetectionResult detectedType =
              _determineNodeType(config, currPath, children);

          // notify plural and split by comma if necessary
          if (detectedType.nodeType == _DetectionType.context ||
              detectedType.nodeType == _DetectionType.pluralCardinal ||
              detectedType.nodeType == _DetectionType.pluralOrdinal) {
            if (children.isEmpty) {
              switch (config.fallbackStrategy) {
                case FallbackStrategy.none:
                  throw '"$currPath" in <$localeDebug> is empty but it is marked for pluralization. Define "fallback_strategy: base_locale" to ignore this node.';
                case FallbackStrategy.baseLocale:
                  return;
              }
            }

            // split children by comma for plurals and contexts
            final digestedMap = <String, StringTextNode>{};
            final entries = children.entries.toList();
            for (final entry in entries) {
              final split = entry.key.split(Node.KEY_DELIMITER);
              if (split.length == 1) {
                // keep as is
                digestedMap[entry.key] = entry.value as StringTextNode;
              } else {
                // split!
                // {one,two: hi} -> {one: hi, two: hi}
                for (final newChild in split) {
                  digestedMap[newChild] = entry.value as StringTextNode;
                }
              }
            }

            final String? paramNameHint =
                RegexUtils.paramHintRegex.firstMatch(originalKey)?.group(1);
            if (detectedType.nodeType == _DetectionType.context) {
              final context = detectedType.contextHint!;
              node = ContextNode(
                path: currPath,
                comment: comment,
                context: context,
                entries: digestedMap,
                paramName: paramNameHint ?? context.defaultParameter,
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
    BuildModelConfig config,
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

      if (childrenSplitByComma.isEmpty) {
        // fallback: empty node is a class by default
        return _DetectionResult(_DetectionType.classType);
      }

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
        if (contextType.paths.contains(nodePath)) {
          return _DetectionResult(_DetectionType.context, contextType);
        } else if (contextType.paths.isEmpty) {
          // empty paths => auto detection
          final isContext = childrenSplitByComma.length ==
                  contextType.enumValues.length &&
              childrenSplitByComma
                  .every((key) => contextType.enumValues.any((e) => e == key));
          if (isContext) {
            return _DetectionResult(_DetectionType.context, contextType);
          }
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
    required InterfaceCollection interfaceCollection,
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
          interfaceCollection: interfaceCollection,
        );
      }
    });

    if (curr is ObjectNode) {
      // check if this node itself is an interface
      final interface = _determineInterface(
        node: curr,
        interfaceCollection: interfaceCollection,
      );
      if (interface != null) {
        curr.setInterface(interface);

        // in case this interface is new
        interfaceCollection.nameInterfaceMap[interface.name] = interface;
      }
    }

    final containerInterface = _determineInterfaceForContainer(
      node: curr,
      interfaceCollection: interfaceCollection,
    );
    if (containerInterface != null) {
      curr.setGenericType(containerInterface.name);
      children
          .cast<ObjectNode>()
          .forEach((child) => child.setInterface(containerInterface));

      // in case this interface is new
      interfaceCollection.nameInterfaceMap[containerInterface.name] =
          containerInterface;
    }

    return interfaceCollection.nameInterfaceMap.values;
  }

  /// Returns the interface of the list or object node.
  /// No side effects.
  static Interface? _determineInterfaceForContainer({
    required IterableNode node,
    required InterfaceCollection interfaceCollection,
  }) {
    final List<ObjectNode> children;
    if (node is ListNode) {
      if (node.entries.isNotEmpty &&
          node.entries.every((child) => child is ObjectNode)) {
        children = node.entries.cast<ObjectNode>().toList();
      } else {
        return null;
      }
    } else if (node is ObjectNode) {
      if (node.entries.isNotEmpty &&
          node.entries.values.every((child) => child is ObjectNode)) {
        children = node.entries.values.cast<ObjectNode>().toList();
      } else {
        return null;
      }
    } else {
      throw 'this should not happen';
    }

    // first check if the path is specified to be an interface (via build config)
    final specifiedInterface =
        interfaceCollection.pathInterfaceContainerMap[node.path];
    if (specifiedInterface != null) {
      final existingInterface =
          interfaceCollection.nameInterfaceMap[specifiedInterface];
      if (existingInterface != null) {
        // user has specified path and attributes for this interface
        if (existingInterface.hasLists) {
          children.forEach((child) {
            _fixEmptyLists(node: child, interface: existingInterface);
          });
        }
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
      final potentialInterface =
          interfaceCollection.globalInterfaces.cast<Interface?>().firstWhere(
                (interface) => Interface.satisfyRequiredSet(
                    requiredSet: interface!.attributes,
                    testSet: commonAttributes),
                orElse: () => null,
              );
      return potentialInterface;
    }
  }

  /// Returns the interface of the object node.
  /// No side effects.
  static Interface? _determineInterface({
    required ObjectNode node,
    required InterfaceCollection interfaceCollection,
  }) {
    // first check if the path is specified to be an interface (via build config)
    final specifiedInterface =
        interfaceCollection.pathInterfaceNameMap[node.path];
    if (specifiedInterface != null) {
      final existingInterface =
          interfaceCollection.nameInterfaceMap[specifiedInterface];
      if (existingInterface != null) {
        // user has specified path and attributes for this interface
        if (existingInterface.hasLists) {
          _fixEmptyLists(node: node, interface: existingInterface);
        }
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
      final potentialInterface =
          interfaceCollection.globalInterfaces.cast<Interface?>().firstWhere(
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
        returnType = child is StringTextNode ? 'String' : 'TextSpan';
        parameters = child.params.map((p) {
          return AttributeParameter(
            parameterName: p,
            type: child.paramTypeMap[p] ?? 'Object',
          );
        }).toSet();
      } else if (child is ListNode) {
        returnType = 'List<${child.genericType}>';
        parameters = {}; // lists never have parameters
      } else if (child is ObjectNode) {
        returnType = 'Map<String, ${child.genericType}>';
        parameters = {}; // objects never have parameters
      } else if (child is PluralNode) {
        returnType = 'String';
        parameters = {
          AttributeParameter(parameterName: child.paramName, type: 'num'),
          ...child.quantities.values
              .cast<StringTextNode>()
              .map((text) => text.params)
              .expand((param) => param)
              .where((param) => param != child.paramName)
              .map((param) =>
                  AttributeParameter(parameterName: param, type: 'Object'))
        };
      } else if (child is ContextNode) {
        returnType = 'String';
        parameters = {
          AttributeParameter(
              parameterName: child.paramName, type: child.context.enumName),
          ...child.entries.values
              .cast<StringTextNode>()
              .map((text) => text.params)
              .expand((param) => param)
              .where((param) => param != child.paramName)
              .map((param) =>
                  AttributeParameter(parameterName: param, type: 'Object'))
        };
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

  /// Applies the generic type defined in the interface for all empty lists.
  ///
  /// By default, empty lists are considered to be List<String>
  /// But when interfaces are used, it can differ: e.g. List<MyType>
  static void _fixEmptyLists({
    required ObjectNode node,
    required Interface interface,
  }) {
    interface.attributes.forEach((attribute) {
      final child = node.entries[attribute.attributeName];
      if (child != null && child is ListNode && child.entries.isEmpty) {
        final match = RegexUtils.genericRegex.firstMatch(attribute.returnType);
        final generic = match?.group(1);
        if (generic != null) {
          child.setGenericType(generic);
        }
      }
    });
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

extension on BuildModelConfig {
  InterfaceCollection buildInterfaceCollection() {
    Set<Interface> globalInterfaces = {};
    Map<String, Interface> nameInterfaceMap = {};
    Map<String, String> pathInterfaceContainerMap = {};
    Map<String, String> pathInterfaceNameMap = {};
    interfaces.forEach((interfaceConfig) {
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
    return InterfaceCollection(
      globalInterfaces: globalInterfaces,
      nameInterfaceMap: nameInterfaceMap,
      pathInterfaceContainerMap: pathInterfaceContainerMap,
      pathInterfaceNameMap: pathInterfaceNameMap,
    );
  }
}
