import 'package:collection/collection.dart';
import 'package:slang/src/builder/model/enums.dart';

extension StringExtensions on String {
  /// capitalizes a given string
  /// 'hello' => 'Hello'
  /// 'Hello' => 'Hello'
  /// '' => ''
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// transforms the string to the specified case
  /// if case is null, then no transformation will be applied
  String toCase(CaseStyle? style) {
    return switch (style) {
      CaseStyle.camel => getWords()
          .mapIndexed((index, word) =>
              index == 0 ? word.toLowerCase() : word.capitalize())
          .join(''),
      CaseStyle.pascal => getWords().map((word) => word.capitalize()).join(''),
      CaseStyle.snake => getWords().map((word) => word.toLowerCase()).join('_'),
      null => this,
    };
  }

  /// de-DE will be interpreted as [de,DE]
  /// normally, it would be [de,D,E] which we do not want
  String toCaseOfLocale(CaseStyle style) {
    return toLowerCase().toCase(style);
  }

  /// get word list from string input
  /// assume that words are separated by special characters or by camel case
  List<String> getWords() {
    final input = this;
    final buffer = StringBuffer();
    final words = <String>[];
    final isAllCaps = input.toUpperCase() == input;

    for (int i = 0; i < input.length; i++) {
      final String currChar = input[i];
      final String? nextChar = i + 1 == input.length ? null : input[i + 1];

      if (_symbolSet.contains(currChar)) {
        continue;
      }

      buffer.write(currChar);

      final bool isEndOfWord = nextChar == null ||
          (!isAllCaps && _upperAlphaRegex.hasMatch(nextChar)) ||
          _symbolSet.contains(nextChar);

      if (isEndOfWord) {
        words.add(buffer.toString());
        buffer.clear();
      }
    }

    return words;
  }
}

final _upperAlphaRegex = RegExp(r'[A-Z]');
final _symbolSet = <String>{' ', '.', '_', '-', '/', '\\'};
