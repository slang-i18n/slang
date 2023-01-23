import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:slang/builder/model/build_model_config.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/context_type.dart';
import 'package:slang/builder/model/interface.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/model/pluralization.dart';
import 'package:slang/builder/utils/regex_utils.dart';
import 'package:slang/builder/utils/string_extensions.dart';

class _Modifiers {
  static const rich = 'rich';
  static const map = 'map';
  static const plural = 'plural';
  static const cardinal = 'cardinal';
  static const ordinal = 'ordinal';
  static const context = 'context';
  static const param = 'param';
  static const interface = 'interface';
  static const singleInterface = 'singleInterface';
}

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
  ///
  /// [handleLinks] can be set false to ignore links at leave them as is
  /// e.g. ${_root.greet(name: name} will be ${_root.greet}
  static BuildModelResult build({
    required BuildModelConfig buildConfig,
    required Map<String, dynamic> map,
    bool handleLinks = true,
    required String localeDebug,
  }) {
    // flat map for leaves (TextNode, PluralNode, ContextNode)
    final Map<String, LeafNode> leavesMap = {};

    // 1st iteration: Build nodes according to given map
    //
    // Linked Translations:
    // They will be tracked but not handled
    // Assumption: They are basic linked translations without parameters
    // Reason: Not all TextNodes are built, so final parameters are unknown
    final resultNodeTree = _parseMapNode(
      localeDebug: localeDebug,
      parentPath: '',
      parentRawPath: '',
      curr: map,
      config: buildConfig,
      keyCase: buildConfig.keyCase,
      leavesMap: leavesMap,
    );

    // 2nd iteration: Handle parameterized linked translations
    //
    // TextNodes with parameterized linked translations are rebuilt with correct parameters.
    if (handleLinks) {
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
              throw '"$key" in <$localeDebug> is linked to "$currLink" but "$currLink" is undefined.';
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
              final Iterable<TextNode> textNodes = linkedNode is PluralNode
                  ? linkedNode.quantities.values
                  : (linkedNode as ContextNode).entries.values;
              final linkedParamSet = textNodes
                  .map((e) => e.params)
                  .expand((params) => params)
                  .toSet();

              if (linkedNode is PluralNode) {
                if (linkedNode.rich) {
                  final builderParam = '${linkedNode.paramName}Builder';
                  linkedParamSet.add(builderParam);
                  paramTypeMap[builderParam] = 'InlineSpan Function(num)';
                  for (final n in textNodes) {
                    paramTypeMap.addAll(n.paramTypeMap);
                  }
                }
                linkedParamSet.add(linkedNode.paramName);
                paramTypeMap[linkedNode.paramName] = 'num';
              } else if (linkedNode is ContextNode) {
                if (linkedNode.rich) {
                  final builderParam = '${linkedNode.paramName}Builder';
                  linkedParamSet.add(builderParam);
                  paramTypeMap[builderParam] =
                      'InlineSpan Function(${linkedNode.context.enumName})';
                  for (final n in textNodes) {
                    paramTypeMap.addAll(n.paramTypeMap);
                  }
                }
                linkedParamSet.add(linkedNode.paramName);
                paramTypeMap[linkedNode.paramName] =
                    linkedNode.context.enumName;
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
    }

    // imaginary root node
    final root = ObjectNode(
      path: '',
      rawPath: '',
      comment: null,
      modifiers: {},
      entries: resultNodeTree,
      isMap: false,
    );

    final interfaceCollection = buildConfig.buildInterfaceCollection();

    // 3rd iteration: Add interfaces
    _applyInterfaceAndGenericsRecursive(
      curr: root,
      interfaceCollection: interfaceCollection,
    );

    return BuildModelResult(
      root: root,
      interfaces: interfaceCollection.resultInterfaces.values.toList(),
    );
  }
}

/// Takes the [curr] map which is (a part of) the raw tree from json / yaml
/// and returns the node model.
Map<String, Node> _parseMapNode({
  required String localeDebug,
  required String parentPath,
  required String parentRawPath,
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
    // the part after '(' is considered as the modifier
    key = key.split('(').first.toCase(keyCase);
    final currPath = parentPath.isNotEmpty ? '$parentPath.$key' : key;
    final currRawPath =
        parentRawPath.isNotEmpty ? '$parentRawPath.$originalKey' : originalKey;

    final comment = _parseCommentNode(curr['@$key']);
    final modifiers = _parseModifiers(originalKey);

    if (value is String || value is num) {
      // leaf
      // key: 'value'
      final textNode = modifiers.containsKey(_Modifiers.rich)
          ? RichTextNode(
              path: currPath,
              rawPath: currRawPath,
              raw: value.toString(),
              comment: comment,
              interpolation: config.stringInterpolation,
              paramCase: config.paramCase,
            )
          : StringTextNode(
              path: currPath,
              rawPath: currRawPath,
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
          parentRawPath: currRawPath,
          curr: listAsMap,
          config: config,
          keyCase: config.keyCase,
          leavesMap: leavesMap,
        );

        // finally only take their values, ignoring keys
        final node = ListNode(
          path: currPath,
          rawPath: currRawPath,
          comment: comment,
          modifiers: modifiers,
          entries: children.values.toList(),
        );
        _setParent(node, children.values);
        resultNodeTree[key] = node;
      } else {
        // key: { ...value }
        children = _parseMapNode(
          localeDebug: localeDebug,
          parentPath: currPath,
          parentRawPath: currRawPath,
          curr: value,
          config: config,
          keyCase: config.keyCase != config.keyMapCase &&
                  (config.maps.contains(currPath) ||
                      modifiers.containsKey(_Modifiers.map))
              ? config.keyMapCase
              : config.keyCase,
          leavesMap: leavesMap,
        );

        Node node;
        _DetectionResult detectedType =
            _determineNodeType(config, currPath, modifiers, children);

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
          Map<String, TextNode> digestedMap = <String, StringTextNode>{};
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

          final rich = modifiers.containsKey(_Modifiers.rich);
          if (rich) {
            // rebuild children as RichText
            digestedMap = _parseMapNode(
              localeDebug: localeDebug,
              parentPath: currPath,
              parentRawPath: currRawPath,
              curr: {
                for (final cKey in digestedMap.keys)
                  cKey._withModifier(_Modifiers.rich): value[cKey],
              },
              config: config,
              keyCase: config.keyCase,
              leavesMap: leavesMap,
            ).cast<String, RichTextNode>();
          }

          if (detectedType.nodeType == _DetectionType.context) {
            final context = detectedType.contextHint!;
            node = ContextNode(
              path: currPath,
              rawPath: currRawPath,
              comment: comment,
              context: context,
              entries: digestedMap,
              paramName:
                  modifiers[_Modifiers.param] ?? context.defaultParameter,
              rich: rich,
            );
          } else {
            node = PluralNode(
              path: currPath,
              rawPath: currRawPath,
              comment: comment,
              pluralType: detectedType.nodeType == _DetectionType.pluralCardinal
                  ? PluralType.cardinal
                  : PluralType.ordinal,
              quantities: digestedMap.map((key, value) {
                // assume that parsing to quantity never fails (hence, never null)
                // because detection was correct
                return MapEntry(key.toQuantity()!, value);
              }),
              paramName: modifiers[_Modifiers.param] ?? config.pluralParameter,
              rich: rich,
            );
          }
        } else {
          node = ObjectNode(
            path: currPath,
            rawPath: currRawPath,
            comment: comment,
            modifiers: modifiers,
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

String? _parseCommentNode(dynamic node) {
  if (node == null) {
    return null;
  }

  if (node is String) {
    // parse string directly
    return node;
  } else if (node is Map<String, dynamic>) {
    // ARB style
    return node['description']?.toString();
  } else {
    return null;
  }
}

void _setParent(Node parent, Iterable<Node> children) {
  children.forEach((child) => child.setParent(parent));
}

_DetectionResult _determineNodeType(
  BuildModelConfig config,
  String nodePath,
  Map<String, String> modifiers,
  Map<String, Node> children,
) {
  final modifierFlags = modifiers.keys.toSet();
  if (modifierFlags.contains(_Modifiers.map) ||
      config.maps.contains(nodePath)) {
    return _DetectionResult(_DetectionType.map);
  } else if (modifierFlags.contains(_Modifiers.plural) ||
      modifierFlags.contains(_Modifiers.cardinal) ||
      config.pluralCardinal.contains(nodePath)) {
    return _DetectionResult(_DetectionType.pluralCardinal);
  } else if (modifierFlags.contains(_Modifiers.ordinal) ||
      config.pluralOrdinal.contains(nodePath)) {
    return _DetectionResult(_DetectionType.pluralOrdinal);
  } else {
    if (modifierFlags.contains(_Modifiers.context)) {
      final modifier = modifiers[_Modifiers.context];
      final context =
          config.contexts.firstWhereOrNull((c) => c.enumName == modifier);
      if (context != null) {
        return _DetectionResult(_DetectionType.context, context);
      }
    }

    final childrenSplitByComma =
        children.keys.expand((key) => key.split(Node.KEY_DELIMITER)).toList();

    if (childrenSplitByComma.isEmpty) {
      // fallback: empty node is a class by default
      return _DetectionResult(_DetectionType.classType);
    }

    if (config.pluralAuto != PluralAuto.off) {
      // check if every children is 'zero', 'one', 'two', 'few', 'many' or 'other'
      final isPlural = childrenSplitByComma.length <= Quantity.values.length &&
          childrenSplitByComma
              .every((key) => Quantity.values.any((q) => q.paramName() == key));
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
void _applyInterfaceAndGenericsRecursive({
  required IterableNode curr,
  required InterfaceCollection interfaceCollection,
}) {
  // first calculate for children (post order!)
  curr.values.forEach((child) {
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
      interfaceCollection.resultInterfaces[interface.name] = interface;
    }
  }

  final containerInterface = _determineInterfaceForContainer(
    node: curr,
    interfaceCollection: interfaceCollection,
  );
  if (containerInterface != null) {
    curr.setGenericType(containerInterface.name);
    curr.values
        .cast<ObjectNode>()
        .forEach((child) => child.setInterface(containerInterface));

    // in case this interface is new
    interfaceCollection.resultInterfaces[containerInterface.name] =
        containerInterface;
  }
}

/// Returns the interface of the list or object node.
/// No side effects.
Interface? _determineInterfaceForContainer({
  required IterableNode node,
  required InterfaceCollection interfaceCollection,
}) {
  if (node.values.isEmpty || node.values.any((child) => child is! ObjectNode)) {
    // All children must be ObjectNode
    return null;
  }

  final List<ObjectNode> children = node.values.cast<ObjectNode>().toList();

  // first check if the path is specified to be an interface (via build config)
  // or the modifier
  // this is executed because we can skip the next complex step
  final specifiedInterface = node.modifiers[_Modifiers.interface] ??
      interfaceCollection.pathInterfaceContainerMap[node.path];

  if (specifiedInterface != null) {
    Interface? existingInterface =
        interfaceCollection.resultInterfaces[specifiedInterface];
    if (existingInterface != null) {
      // there is already an interface for this name
      if (!interfaceCollection.originalInterfaces
          .containsKey(specifiedInterface)) {
        // This interface is inferred, extend its attributes if necessary
        final attributes = _parseInterfaceContainerAttributes(children);
        existingInterface = existingInterface.extend({
          ...attributes.common,
          ...attributes.optional,
        });
        interfaceCollection.resultInterfaces[specifiedInterface] =
            existingInterface;
      }
      if (existingInterface.hasLists) {
        for (final child in children) {
          _fixEmptyLists(node: child, interface: existingInterface);
        }
      }
      return existingInterface;
    }

    // user has specified the path but not the concrete attributes
    // create the corresponding concrete interface here
    final attributes = _parseInterfaceContainerAttributes(children);
    return Interface(
      name: specifiedInterface,
      attributes: {...attributes.common, ...attributes.optional},
    );
  } else if (interfaceCollection.globalInterfaces.isNotEmpty) {
    // lets find the first interface that satisfy this hypothetical interface
    // only one interface is allowed because generics do not allow unions
    final attributes = _parseInterfaceContainerAttributes(children);
    final potentialInterface =
        interfaceCollection.globalInterfaces.values.firstWhereOrNull(
      (interface) => Interface.satisfyRequiredSet(
        requiredSet: interface.attributes,
        testSet: attributes.common,
      ),
    );
    return potentialInterface;
  } else {
    return null;
  }
}

/// find minimum attribute set all object nodes have in common
/// and a super set containing all attributes of all object nodes
_InterfaceAttributesResult _parseInterfaceContainerAttributes(
    List<ObjectNode> children) {
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

  return _InterfaceAttributesResult(
    common: commonAttributes,
    all: allAttributes,
    optional: optionalAttributes,
  );
}

/// Returns the interface of the object node.
/// No side effects.
Interface? _determineInterface({
  required ObjectNode node,
  required InterfaceCollection interfaceCollection,
}) {
  // first check if the path is specified to be an interface (via build config)
  // or the modifier
  // this is executed because we can skip the next complex step
  final specifiedInterface = node.modifiers[_Modifiers.singleInterface] ??
      interfaceCollection.pathInterfaceNameMap[node.path];

  if (specifiedInterface != null) {
    Interface? existingInterface =
        interfaceCollection.resultInterfaces[specifiedInterface];
    if (existingInterface != null) {
      // user has specified path and attributes for this interface
      if (!interfaceCollection.originalInterfaces
          .containsKey(specifiedInterface)) {
        // This interface is inferred, extend its attributes if necessary
        existingInterface = existingInterface.extend(_parseAttributes(node));
        interfaceCollection.resultInterfaces[specifiedInterface] =
            existingInterface;
      }
      if (existingInterface.hasLists) {
        _fixEmptyLists(node: node, interface: existingInterface);
      }
      return existingInterface;
    }

    // user has specified the path but not the concrete attributes
    // create the corresponding concrete interface here
    return Interface(
      name: specifiedInterface,
      attributes: _parseAttributes(node),
    );
  } else if (interfaceCollection.globalInterfaces.isNotEmpty) {
    // lets find the first interface that satisfy this hypothetical interface
    // only one interface is allowed because generics do not allow unions
    final attributes = _parseAttributes(node);
    final potentialInterface =
        interfaceCollection.globalInterfaces.values.firstWhereOrNull(
      (interface) => Interface.satisfyRequiredSet(
        requiredSet: interface.attributes,
        testSet: attributes,
      ),
    );
    return potentialInterface;
  } else {
    return null;
  }
}

/// Finds the attributes of the object node.
/// No side effects.
Set<InterfaceAttribute> _parseAttributes(ObjectNode node) {
  return node.entries.entries.map((entry) {
    final child = entry.value;
    final String returnType;
    final Set<AttributeParameter> parameters;
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
      returnType = child.rich ? 'TextSpan' : 'String';
      parameters = child.getParameters();
    } else if (child is ContextNode) {
      returnType = child.rich ? 'TextSpan' : 'String';
      parameters = child.getParameters();
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
void _fixEmptyLists({
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

/// Returns a map containing modifiers
/// greet(param: gender, rich)
/// will result in
/// {param: gender, rich: rich)
Map<String, String> _parseModifiers(String originalKey) {
  final String? modifierSection =
      RegexUtils.modifierRegex.firstMatch(originalKey)?.group(1);
  if (modifierSection == null) {
    return {};
  }

  final modifiers = modifierSection.split(',');
  final resultMap = <String, String>{};
  for (final modifier in modifiers) {
    if (modifier.contains('=')) {
      final parts = modifier.split('=');
      if (parts.length != 2) {
        throw 'Hints must be in format "key: value" or "key"';
      }

      resultMap[parts[0].trim()] = parts[1].trim();
    } else {
      final modifierDigested = modifier.trim();
      resultMap[modifierDigested] = modifierDigested;
    }
  }
  return resultMap;
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

class _InterfaceAttributesResult {
  final Set<InterfaceAttribute> common;
  final Set<InterfaceAttribute> all;
  final Set<InterfaceAttribute> optional;

  _InterfaceAttributesResult({
    required this.common,
    required this.all,
    required this.optional,
  });
}

extension on BuildModelConfig {
  InterfaceCollection buildInterfaceCollection() {
    Map<String, Interface> originalInterfaces = {};
    Map<String, Interface> globalInterfaces = {};
    Map<String, String> pathInterfaceContainerMap = {};
    Map<String, String> pathInterfaceNameMap = {};
    for (final interfaceConfig in interfaces) {
      final Interface? interface;
      if (interfaceConfig.attributes.isNotEmpty) {
        interface = interfaceConfig.toInterface();
        originalInterfaces[interface.name] = interface;
      } else {
        interface = null;
      }

      if (interfaceConfig.paths.isEmpty && interface != null) {
        globalInterfaces[interface.name] = interface;
      } else {
        interfaceConfig.paths.forEach((path) {
          if (path.isContainer) {
            pathInterfaceContainerMap[path.path] = interfaceConfig.name;
          } else {
            pathInterfaceNameMap[path.path] = interfaceConfig.name;
          }
        });
      }
    }
    return InterfaceCollection(
      originalInterfaces: originalInterfaces,
      globalInterfaces: globalInterfaces,
      resultInterfaces: {...originalInterfaces},
      pathInterfaceContainerMap: pathInterfaceContainerMap,
      pathInterfaceNameMap: pathInterfaceNameMap,
    );
  }
}

extension on String {
  /// Add a modifier to a key
  /// myKey -> myKey(modifier)
  /// myKey(rich) -> myKey(rich,modifier)
  String _withModifier(String mKey, [String? mValue]) {
    final modifier = '$mKey${mValue != null ? '=$mValue' : ''}';
    if (this.contains('(')) {
      final trimmed = this.trim();
      return '${trimmed.substring(0, trimmed.length - 1)},$modifier)';
    } else {
      return '$this($modifier)';
    }
  }
}
