import 'package:slang/src/builder/model/i18n_locale.dart';

class ParseL10nResult {
  /// The actual parameter type.
  /// Is [num] for [NumberFormat] and [DateTime] for [DateFormat].
  final String paramType;

  /// The format string that will be rendered as is.
  final String format;

  ParseL10nResult({
    required this.paramType,
    required this.format,
  });
}

const _numberFormats = {
  'compact',
  'compactCurrency',
  'compactSimpleCurrency',
  'compactLong',
  'currency',
  'decimalPattern',
  'decimalPatternDigits',
  'decimalPercentPattern',
  'percentPattern',
  'scientificPattern',
  'simpleCurrency',
};

const _numberFormatsWithNamedParameters = {
  'NumberFormat.compactCurrency',
  'NumberFormat.compactSimpleCurrency',
  'NumberFormat.currency',
  'NumberFormat.decimalPatternDigits',
  'NumberFormat.decimalPercentPattern',
  'NumberFormat.simpleCurrency',
};

final _numberFormatsWithClass = {
  for (final format in _numberFormats) 'NumberFormat.$format',
  'NumberFormat',
};

const _dateFormats = {
  'yM',
  'yMd',
  'Hm',
  'Hms',
  'jm',
  'jms',
};

final _dateFormatsWithClass = {
  for (final format in _dateFormats) 'DateFormat.$format',
  'DateFormat',
};

// Parses "currency(symbol: '€')"
// -> paramType: num, format: NumberFormat.currency(symbol: '€', locale: locale).format(value)
ParseL10nResult? parseL10n({
  required I18nLocale locale,
  required String paramName,
  required String type,
}) {
  final bracketStart = type.indexOf('(');

  // The type without parameters.
  // E.g. currency(symbol: '€') -> currency
  final digestedType =
      bracketStart == -1 ? type : type.substring(0, bracketStart);

  final String paramType;
  if (_numberFormats.contains(digestedType) ||
      _numberFormatsWithClass.contains(digestedType)) {
    paramType = 'num';
  } else if (_dateFormats.contains(digestedType) ||
      _dateFormatsWithClass.contains(digestedType)) {
    paramType = 'DateTime';
  } else {
    return null;
  }

  String methodName;
  String arguments;

  if (bracketStart != -1 && type.endsWith(')')) {
    methodName = type.substring(0, bracketStart);
    arguments = type.substring(bracketStart + 1, type.length - 1);
  } else {
    methodName = type;
    arguments = '';
  }

  // Prepend class if necessary
  if (!type.startsWith('NumberFormat(') &&
      !type.startsWith('DateFormat(') &&
      !methodName.startsWith('NumberFormat.') &&
      !methodName.startsWith('DateFormat.')) {
    if (paramType == 'num') {
      methodName = 'NumberFormat.$methodName';
    } else if (paramType == 'DateTime') {
      methodName = 'DateFormat.$methodName';
    }
  }

  // Add locale
  if (paramType == 'num' &&
      _numberFormatsWithNamedParameters.contains(methodName)) {
    // add locale as named parameter
    if (arguments.isEmpty) {
      arguments = "locale: '${locale.underscoreTag}'";
    } else {
      arguments = "$arguments, locale: '${locale.underscoreTag}'";
    }
  } else {
    // add locale as positional parameter
    if (!arguments.contains('locale:')) {
      if (arguments.isEmpty) {
        arguments = "'${locale.underscoreTag}'";
      } else {
        arguments = "$arguments, '${locale.underscoreTag}'";
      }
    }
  }

  return ParseL10nResult(
    paramType: paramType,
    format: '$methodName($arguments).format($paramName)',
  );
}
