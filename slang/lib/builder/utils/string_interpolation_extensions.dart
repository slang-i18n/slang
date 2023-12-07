const _DOLLAR = '\$';
final _nonWordRegex = RegExp(r'[^\w]');

extension StringInterpolationExtensions on String {
  /// Replaces every $x or ${x} with the result of [replacer].
  String replaceDartInterpolation({
    required String Function(String match) replacer,
  }) {
    String curr = this;
    final buffer = StringBuffer();

    do {
      int startCharacterLength = 1;
      int startIndex = curr.indexOf(_DOLLAR);
      if (startIndex == -1) {
        // no more matches
        buffer.write(curr);
        break;
      }

      // Check if the $ is escaped with a preceding \
      if (startIndex >= 1 && curr[startIndex - 1] == '\\') {
        buffer.write(curr.substring(0, startIndex)); // *do* include \
        buffer.write(_DOLLAR);
        if (startIndex + 1 < curr.length) {
          curr = curr.substring(startIndex + 1);
          continue;
        } else {
          break;
        }
      }

      if (startIndex != 0) {
        // Add everything before the $ to the buffer
        buffer.write(curr.substring(0, startIndex));
      }

      if (startIndex + 1 < curr.length) {
        final nextCharacter = curr[startIndex + 1];
        if (nextCharacter == '{') {
          startCharacterLength = 2; // it is now "${"
        } else if (nextCharacter.contains(_nonWordRegex)) {
          // $ stands alone
          buffer.write(_DOLLAR);
          curr = curr.substring(startIndex + 1);
          continue;
        }
      }

      final endRegex = startCharacterLength == 1 ? _nonWordRegex : '}';
      int endIndex = curr.indexOf(endRegex, startIndex + startCharacterLength);
      if (endIndex == -1) {
        if (startCharacterLength == 1 && startIndex + 1 < curr.length) {
          // $arg goes to the end
          buffer.write(replacer(curr.substring(startIndex)));
        } else {
          // ${ has no }, therefore no transformation
          // or single $ in the end
          buffer.write(curr.substring(startIndex));
        }
        break;
      }

      final endCharacterLength = startCharacterLength == 1 ? 0 : 1;
      buffer.write(
          replacer(curr.substring(startIndex, endIndex + endCharacterLength)));
      curr = curr.substring(endIndex + endCharacterLength);
    } while (curr.isNotEmpty);

    return buffer.toString();
  }

  /// Replaces every ${x} with the result of [replacer].
  /// Escaped \${x} will be transformed to ${x} without replacer call
  String replaceDartNormalizedInterpolation({
    required String Function(String match) replacer,
  }) {
    return _replaceBetween(
      input: this,
      startCharacter: r'${',
      endCharacter: '}',
      replacer: replacer,
    );
  }

  /// Replaces every {x} with the result of [replacer].
  String replaceBracesInterpolation({
    required String Function(String match) replacer,
  }) {
    return _replaceBetween(
      input: this,
      startCharacter: '{',
      endCharacter: '}',
      replacer: replacer,
    );
  }

  /// Replaces every {{x}} with the result of [replacer].
  String replaceDoubleBracesInterpolation({
    required String Function(String match) replacer,
  }) {
    return _replaceBetween(
      input: this,
      startCharacter: '{{',
      endCharacter: '}}',
      replacer: replacer,
    );
  }
}

String _replaceBetween({
  required String input,
  required String startCharacter,
  required String endCharacter,
  required String Function(String match) replacer,
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
    if (startIndex >= 1 && curr[startIndex - 1] == '\\') {
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

    int endIndex =
        curr.indexOf(endCharacter, startIndex + startCharacterLength);
    if (endIndex == -1) {
      buffer.write(curr.substring(startIndex));
      break;
    }

    buffer.write(
        replacer(curr.substring(startIndex, endIndex + endCharacterLength)));
    curr = curr.substring(endIndex + endCharacterLength);
  } while (curr.isNotEmpty);

  return buffer.toString();
}
