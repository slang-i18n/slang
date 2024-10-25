extension OverrideStringExt on String {
  /// Splits the string by comma, ignoring commas inside quotes, and
  /// trims the parts.
  List<String> splitParameters() {
    if (isEmpty) {
      return [];
    }

    final parts = <String>[];
    final characters = split('');
    final result = StringBuffer();
    bool inQuotes = false;
    for (final c in characters) {
      if (c == ',') {
        if (inQuotes) {
          result.write(c);
        } else {
          parts.add(result.toString().trim());
          result.clear();
        }
      } else {
        if (c == "'" || c == '"') {
          inQuotes = !inQuotes;
        }
        result.write(c);
      }
    }
    parts.add(result.toString().trim());
    return parts;
  }
}
