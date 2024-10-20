import 'package:intl/intl.dart';

class ValueFormatter {
  /// Is either [NumberFormat] or [DateFormat].
  /// Unfortunately, there is no super class for both.
  final Object Function() _formatter;

  /// The actual formatter.
  /// We delay the initialization to ensure that intl is already initialized
  /// by Flutter before we create the formatter.
  late final Object formatter = _formatter();

  ValueFormatter(this._formatter);

  /// Formats the given [value] with the formatter.
  String format(Object value) {
    switch (formatter) {
      case NumberFormat formatter:
        return formatter.format(value as num);
      case DateFormat formatter:
        return formatter.format(value as DateTime);
      default:
        throw Exception('Unknown formatter: $formatter');
    }
  }
}
