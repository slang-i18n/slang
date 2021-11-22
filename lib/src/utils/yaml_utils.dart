class YamlUtils {

  /// converts Map<dynamic, dynamic> to Map<String, dynamic> for all children
  /// forcing all keys to be strings
  static Map<String, dynamic> deepCast(Map<dynamic, dynamic> source) {
    return source.map((key, value) {
      final castedValue;
      if (value is Map) {
        castedValue = deepCast(value);
      } else if (value is List) {
        castedValue = _deepCastList(value);
      } else {
        castedValue = value;
      }
      return MapEntry(key.toString(), castedValue);
    });
  }

  /// Helper function for [deepCast] handling lists
  static List<dynamic> _deepCastList(List<dynamic> source) {
    return source.map((item) {
      if (item is Map) {
        return deepCast(item);
      } else if (item is List) {
        return _deepCastList(item);
      } else {
        return item;
      }
    }).toList();
  }
}