String convertToYaml(Map<String, dynamic> content) {
  return _convertMapToYaml(content, 0);
}

String _convertMapToYaml(Map<String, dynamic> map, int indent) {
  final buffer = StringBuffer();
  final indentStr = '  ' * indent;

  map.forEach((key, value) {
    buffer.write('$indentStr${_sanitizeStringValue(key)}: ');

    if (value is Map<String, dynamic>) {
      buffer.writeln();
      buffer.write(_convertMapToYaml(value, indent + 1));
    } else if (value is List) {
      buffer.writeln();
      buffer.write(_convertListToYaml(value, indent + 1));
    } else {
      buffer.writeln(_formatScalarValue(value));
    }
  });

  return buffer.toString();
}

String _convertListToYaml(List list, int indent) {
  final buffer = StringBuffer();
  final indentStr = '  ' * indent;

  for (var item in list) {
    buffer.write('$indentStr- ');

    if (item is Map<String, dynamic>) {
      buffer.writeln();
      buffer.write(_convertMapToYaml(item, indent + 1));
    } else if (item is List) {
      buffer.writeln();
      buffer.write(_convertListToYaml(item, indent + 1));
    } else {
      buffer.writeln(_formatScalarValue(item));
    }
  }

  return buffer.toString();
}

String _formatScalarValue(dynamic value) {
  if (value is String) {
    if (value.contains('\n')) {
      // Using pipe notation for multiline strings
      final lines = value.split('\n');
      final endsWithNewline = value.endsWith('\n');
      final buffer = StringBuffer(endsWithNewline ? '|\n' : '|-\n');
      for (final line in lines) {
        buffer.write('  $line\n');
      }
      return buffer.toString().trimRight();
    } else {
      return _sanitizeStringValue(value);
    }
  } else {
    return value.toString();
  }
}

/// Sanitizes a string value for YAML formatting.
/// Optionally adds quotes to the string.
String _sanitizeStringValue(String value) {
  if (value.isEmpty ||
      value.contains(':') ||
      value.contains(' #') ||
      _hasLeadingOrTrailingWhitespace(value) ||
      value.startsWith('"') ||
      value.startsWith("'") ||
      value.startsWith('@') ||
      value.startsWith('&') ||
      value.startsWith('|') ||
      value.startsWith('>') ||
      value.startsWith('!') ||
      value.startsWith('?') ||
      value.startsWith('*') ||
      value.startsWith('%') ||
      value.startsWith('`') ||
      value.startsWith('-') ||
      value.startsWith('.') ||
      value.startsWith(',') ||
      value.startsWith('{') ||
      value.startsWith('}') ||
      value.startsWith('[') ||
      value.startsWith(']')) {
    return '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
  }

  return value;
}

bool _hasLeadingOrTrailingWhitespace(String value) {
  return value.codeUnitAt(0) <= 32 || value.codeUnitAt(value.length - 1) <= 32;
}
