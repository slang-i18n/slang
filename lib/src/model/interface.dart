import 'package:collection/collection.dart';

final _setEquality = SetEquality();

/// The config from build.yaml
class InterfaceConfig {
  final String name;
  final Set<InterfaceAttribute> attributes;
  final Set<String> paths;

  InterfaceConfig({
    required this.name,
    required this.attributes,
    required this.paths,
  });
}

/// The interface model used for generation
/// equals and hash are only dependent on attributes
class Interface {
  final String name;
  final Set<InterfaceAttribute> attributes;

  Interface({required this.name, required this.attributes});

  @override
  int get hashCode {
    return _setEquality.hash(attributes);
  }

  @override
  bool operator ==(Object other) {
    return other is Interface &&
        _setEquality.equals(attributes, other.attributes);
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
}
