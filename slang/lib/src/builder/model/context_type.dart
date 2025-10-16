/// Parsed from build config.
/// Enum values may be null. In this case, they will be inferred during model build step.
class ContextType {
  static const String defaultParameterSlang = 'context';

  final String enumName;
  final String defaultParameter;
  final bool generateEnum;

  ContextType({
    required this.enumName,
    required this.defaultParameter,
    required this.generateEnum,
  });

  PendingContextType toPending() {
    return PendingContextType(
      enumName: enumName,
      defaultParameter: defaultParameter,
      generateEnum: generateEnum,
    );
  }
}

/// Used during model build step.
class PendingContextType {
  final String enumName;

  /// Always null in the beginning.
  /// Will be inferred during the model build step.
  List<String>? enumValues;

  final String defaultParameter;
  final bool generateEnum;

  PendingContextType({
    required this.enumName,
    required this.defaultParameter,
    required this.generateEnum,
  });
}

/// Used for the generate step.
class PopulatedContextType {
  final String enumName;
  final List<String> enumValues;
  final bool generateEnum;

  PopulatedContextType({
    required this.enumName,
    required this.enumValues,
    required this.generateEnum,
  });
}
