class ContextType {
  static const bool defaultAuto = true;
  static const List<String> defaultPaths = <String>[];

  final String enumName;
  final List<String> enumValues;
  final bool auto;
  final List<String> paths;

  ContextType({
    required this.enumName,
    required this.enumValues,
    required this.auto,
    required this.paths,
  });
}
