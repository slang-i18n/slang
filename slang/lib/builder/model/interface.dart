import 'package:collection/collection.dart';

final _setEquality = SetEquality();

/// The config from build.yaml
class InterfaceConfig {
  final String name;
  final Set<InterfaceAttribute> attributes;
  final List<InterfacePath> paths;

  InterfaceConfig({
    required this.name,
    required this.attributes,
    required this.paths,
  });
}

class InterfacePath {
  final String path;

  /// true, if the path ends with '.*', all children have the same interface
  /// false, otherwise, i.e. this path itself will get an interface
  final bool isContainer;

  InterfacePath(String path)
      : path = path.replaceAll('.*', ''),
        isContainer = path.endsWith('.*');
}

/// The interface model used for generation
/// equals and hash are only dependent on attributes
class Interface {
  final String name;
  final Set<InterfaceAttribute> attributes;

  /// True, if at least one attribute is a list
  final bool hasLists;

  Interface({required this.name, required this.attributes})
      : hasLists = attributes.any((a) => a.returnType.startsWith('List<'));

  @override
  int get hashCode {
    return _setEquality.hash(attributes);
  }

  @override
  bool operator ==(Object other) {
    return other is Interface && equalAttributes(attributes, other.attributes);
  }

  @override
  String toString() {
    return '$name [${attributes.join(', ')}]';
  }

  /// Extend this interface with another interface.
  /// If an attribute only exists one interface, then make it optional.
  Interface extend(Set<InterfaceAttribute> otherAttributes) {
    if (equalAttributes(attributes, otherAttributes)) {
      return this;
    }

    final Map<String, InterfaceAttribute> extendedAttributes = {};
    final otherAttributesMap = {
      for (final attribute in otherAttributes)
        attribute.attributeName: attribute,
    };
    for (final attribute in attributes) {
      if (!attribute.optional &&
          (otherAttributesMap[attribute.attributeName]?.optional ?? true)) {
        // This mandatory attribute does not exist in the other interface
        // Or the attribute is optional in the other interface
        // Make it optional.
        extendedAttributes[attribute.attributeName] =
            attribute.copyAsOptional();
      } else {
        extendedAttributes[attribute.attributeName] = attribute;
      }
    }
    for (final attribute in otherAttributes) {
      if (!attribute.optional &&
          (extendedAttributes[attribute.attributeName]?.optional ?? true)) {
        // Make it optional.
        extendedAttributes[attribute.attributeName] =
            attribute.copyAsOptional();
      } else {
        extendedAttributes[attribute.attributeName] = attribute;
      }
    }
    return Interface(
      name: name,
      attributes: extendedAttributes.values.toSet(),
    );
  }

  static bool equalAttributes(
    Set<InterfaceAttribute> a,
    Set<InterfaceAttribute> b,
  ) {
    return _setEquality.equals(a, b);
  }

  /// True if,
  /// every non-optional attribute in [requiredSet] also exists in [testSet].
  /// every optional attribute in [requiredSet] which also exist in [testSet] must have the same signature.
  static bool satisfyRequiredSet({
    required Set<InterfaceAttribute> requiredSet,
    required Set<InterfaceAttribute> testSet,
  }) {
    for (final attribute in requiredSet) {
      if (attribute.optional) {
        for (final testAttribute in testSet) {
          if (attribute.attributeName == testAttribute.attributeName) {
            if (attribute.returnType != testAttribute.returnType ||
                !_setEquality.equals(
                    attribute.parameters, testAttribute.parameters)) {
              // this optional attribute also exists in testSet but with a different signature
              return false;
            }
            break;
          }
        }
      } else if (!testSet.contains(attribute)) {
        // this non-optional attribute does not exist in testSet
        return false;
      }
    }
    return true;
  }
}

class InterfaceAttribute {
  final String attributeName;
  final String returnType;
  final Set<AttributeParameter> parameters;
  final bool optional;

  InterfaceAttribute({
    required this.attributeName,
    required this.returnType,
    required this.parameters,
    required this.optional,
  });

  /// A copy of this attribute but make it optional.
  InterfaceAttribute copyAsOptional() {
    return InterfaceAttribute(
      attributeName: attributeName,
      returnType: returnType,
      parameters: parameters,
      optional: true,
    );
  }

  @override
  int get hashCode {
    return attributeName.hashCode *
        returnType.hashCode *
        _setEquality.hash(parameters) *
        optional.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return other is InterfaceAttribute &&
        attributeName == other.attributeName &&
        returnType == other.returnType &&
        _setEquality.equals(parameters, other.parameters) &&
        optional == other.optional;
  }

  @override
  String toString() {
    return '$returnType${optional ? '?' : ''} $attributeName${parameters.isNotEmpty ? '(${parameters.join(', ')})' : ''}';
  }
}

class AttributeParameter {
  final String parameterName;
  final String type;

  AttributeParameter({required this.parameterName, required this.type});

  @override
  int get hashCode {
    return parameterName.hashCode * type.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return other is AttributeParameter &&
        parameterName == other.parameterName &&
        type == other.type;
  }

  @override
  String toString() {
    return '$type $parameterName';
  }
}

extension InterfaceConfigExt on InterfaceConfig {
  Interface toInterface() {
    return Interface(name: name, attributes: attributes);
  }
}

/// Interface collection defined in build.yaml + detected in a locale
class InterfaceCollection {
  // FINAL
  // Original interfaces with attributes specified in config
  // Interface Name -> Interface
  final Map<String, Interface> originalInterfaces;

  // FINAL!
  // Interfaces with no specified path
  // will be applied globally
  // Interface Name -> Interface
  final Map<String, Interface> globalInterfaces;

  // MODIFIABLE!
  // Interface Name -> Interface
  // This may be smaller than [pathInterfaceNameMap] because the user may
  // specify an interface without attributes - in this case the interface
  // will be inferred (i.e. created afterwards).
  // This is the resulting set of interfaces
  final Map<String, Interface> resultInterfaces;

  // FINAL!
  // Path -> Interface Name (all children of this path)
  final Map<String, String> pathInterfaceContainerMap;

  // FINAL!
  // Path -> Interface Name (the node at this path itself)
  final Map<String, String> pathInterfaceNameMap;

  InterfaceCollection({
    required this.originalInterfaces,
    required this.globalInterfaces,
    required this.resultInterfaces,
    required this.pathInterfaceContainerMap,
    required this.pathInterfaceNameMap,
  });
}
