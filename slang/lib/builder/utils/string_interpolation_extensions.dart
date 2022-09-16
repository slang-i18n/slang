extension StringInterpolationExtensions on String {
  String replaceBracesInterpolation({
    required String Function(String match) replace,
  }) {
    return _replaceBetween(
      input: this,
      startCharacter: '{',
      endCharacter: '}',
      replace: replace,
    );
  }

  String replaceDoubleBracesInterpolation({
    required String Function(String match) replace,
  }) {
    return _replaceBetween(
      input: this,
      startCharacter: '{{',
      endCharacter: '}}',
      replace: replace,
    );
  }
}

String _replaceBetween({
  required String input,
  required String startCharacter,
  required String endCharacter,
  required String Function(String match) replace,
}) {
  String curr = input;
  final buffer = StringBuffer();
  final startCharacterLength = startCharacter.length;
  final endCharacterLength = endCharacter.length;

  do {
    int startIndex = curr.indexOf(startCharacter);
    if (startIndex == -1) {
      buffer.write(curr);
      break;
    }
    if (startIndex >= startCharacterLength && curr[startIndex - 1] == '\\') {
      // ignore because of preceding \
      buffer.write(curr.substring(0, startIndex - 1)); // do not include \
      buffer.write(startCharacter);
      if (startIndex + 1 < curr.length) {
        curr = curr.substring(startIndex + startCharacterLength);
        continue;
      } else {
        break;
      }
    }

    if (startIndex != 0) {
      // add prefix
      buffer.write(curr.substring(0, startIndex));
    }

    int endIndex = curr.indexOf(endCharacter);
    if (endIndex == -1) {
      buffer.write(curr);
      break;
    }

    buffer.write(
        replace(curr.substring(startIndex, endIndex + endCharacterLength)));
    curr = curr.substring(endIndex + endCharacterLength);
  } while (curr.isNotEmpty);

  return buffer.toString();
}
