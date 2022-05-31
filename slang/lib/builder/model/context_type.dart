class ContextType {
  static const String DEFAULT_PARAMETER = 'context';
  static const List<String> defaultPaths = <String>[];
  static const bool defaultGenerateEnum = true;

  final String enumName;
  final List<String> enumValues;
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
