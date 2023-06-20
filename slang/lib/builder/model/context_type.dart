/// Parsed from build config.
/// Enum values may be null. In this case, they will be inferred during model build step.
class ContextType {
  static const String DEFAULT_PARAMETER = 'context';
  static const List<String> defaultPaths = <String>[];
  static const bool defaultGenerateEnum = true;

  final String enumName;
  final List<String>? enumValues;
  final List<String> paths;
  final String defaultParameter;
  final bool generateEnum;

  ContextType({
    required this.enumName,
    required this.enumValues,
    required this.paths,
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
