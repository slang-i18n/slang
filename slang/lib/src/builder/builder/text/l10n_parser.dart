import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/utils/parameter_string_ext.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';

class ParseL10nResult {
  /// The actual parameter type.
  /// Is [num] for [NumberFormat] and [DateTime] for [DateFormat].
  final String paramType;

  /// The format string that will be rendered as is.
  /// E.g. NumberFormat.currency(locale: 'en').format(value)
  final String format;

  ParseL10nResult({
    required this.paramType,
    required this.format,
  });
}

const numberFormats = {
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

const numberFormatsWithNamedParameters = {
  'NumberFormat.compact',
  'NumberFormat.compactCurrency',
  'NumberFormat.compactSimpleCurrency',
  'NumberFormat.compactLong',
  'NumberFormat.currency',
  'NumberFormat.decimalPatternDigits',
  'NumberFormat.decimalPercentPattern',
  'NumberFormat.simpleCurrency',
};

final numberFormatsWithClass = {
  for (final format in numberFormats) 'NumberFormat.$format',
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

const positionalWith2Arguments = {
  'DateFormat',
  'NumberFormat',
};

final _dateFormatsWithClass = {
  for (final format in _dateFormats) 'DateFormat.$format',
  'DateFormat',
};

class L10nIntermediateResult {
  final String paramType;
  final String methodName;
  final String? arguments;

  L10nIntermediateResult({
    required this.paramType,
    required this.methodName,
    required this.arguments,
  });
}

L10nIntermediateResult? parseL10nIntermediate(String type) {
  final parsed = RegexUtils.formatTypeRegex.firstMatch(type);
  if (parsed == null) {
    return null;
  }

  String methodName = parsed.group(1)!;
  final arguments = parsed.group(2);

  final String paramType;
  if (numberFormats.contains(methodName) ||
      numberFormatsWithClass.contains(methodName)) {
    paramType = 'num';
  } else if (_dateFormats.contains(methodName) ||
      _dateFormatsWithClass.contains(methodName)) {
    paramType = 'DateTime';
  } else {
    return null;
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

  return L10nIntermediateResult(
    paramType: paramType,
    methodName: methodName,
    arguments: arguments?.trim(),
  );
}

// Parses "currency(symbol: '€')"
// -> paramType: num, format: NumberFormat.currency(symbol: '€', locale: locale).format(value)
ParseL10nResult? parseL10n({
  required I18nLocale locale,
  required String paramName,
  required String type,
}) {
  final parsed = parseL10nIntermediate(type);
  if (parsed == null) {
    return null;
  }

  // Add locale
  String arguments = parsed.arguments ?? '';
  if (parsed.paramType == 'num' &&
      numberFormatsWithNamedParameters.contains(parsed.methodName)) {
    // add locale as named parameter
    if (!arguments.contains('locale')) {
      if (parsed.arguments == null) {
        arguments = "locale: '${locale.underscoreTag}'";
      } else {
        arguments = "$arguments, locale: '${locale.underscoreTag}'";
      }
    }
  } else {
    // add locale as positional parameter
    final has2Arguments = positionalWith2Arguments.contains(parsed.methodName);
    final containsLocale = switch (has2Arguments) {
      // If there is only 1 argument, then it is the locale
      false => arguments.trim().isNotEmpty,
      // If there are 2 arguments, then the locale is the second one
      true => arguments.splitParameters().length >= 2,
    };

    if (!containsLocale) {
      if (arguments.isEmpty) {
        arguments = "'${locale.underscoreTag}'";
      } else {
        arguments = "$arguments, '${locale.underscoreTag}'";
      }
    }
  }

  return ParseL10nResult(
    paramType: parsed.paramType,
    format: '${parsed.methodName}($arguments).format($paramName)',
  );
}
