import 'package:collection/collection.dart';

class BracketsUtils {
  static List<BracketRange> findTopLevelBrackets(
    String input, {
    String openingBracket = '{',
    String closingBracket = '}',
  }) {
    final characters = input.split('');
    final result = <BracketRange>[];
    int start = -1;
    int counter = 0;
    characters.forEachIndexed((index, c) {
      if (c == openingBracket) {
        counter++;
        if (counter == 1) {
          // first opening bracket
          start = index;
        }
      } else if (c == closingBracket) {
        counter--;
        if (counter == 0) {
          result.add(BracketRange(characters, start, index));
        } else if (counter < 0) {
          // invalid closing bracket
          // just find the next opening bracket
          counter = 0;
        }
      }
    });

    return result;
  }
}

class BracketRange {
  /// Position of opening bracket
  final int start;

  /// Position of closing bracket
  final int end;

  /// Original string as character list
  final List<String> fullString;

  BracketRange(this.fullString, this.start, this.end);

  /// Substring of this range
  String substring() {
    return fullString.join('').substring(start, end + 1);
  }

  /// Replace string of this range with another
  String replaceWith(String replace) {
    final joinedString = fullString.join('');
    if (end == fullString.length - 1) {
      // no suffix
      return '${joinedString.substring(0, start)}$replace';
    } else {
      // with suffix
      return '${joinedString.substring(0, start)}$replace${joinedString.substring(end + 1, fullString.length)}';
    }
  }

  @override
  bool operator ==(Object other) {
    return other is BracketRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode * end.hashCode;

  @override
  String toString() {
    return '[$start...$end]';
  }
}
