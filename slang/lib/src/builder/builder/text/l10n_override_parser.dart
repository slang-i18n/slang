import 'package:intl/intl.dart';
import 'package:slang/src/api/formatter.dart';
import 'package:slang/src/builder/builder/text/l10n_parser.dart';

class L10nOverrideResult {
  final String methodName;
  final Map<Symbol, dynamic> params;

  L10nOverrideResult({
    required this.methodName,
    required this.params,
  });

  String format(Object value) {
    final Function f = NumberFormat.currency;
    final dynamic formatter = Function.apply(f, const [], params);
    return formatter.format(value);
  }
}

/// Converts a type definition to an actual value.
/// e.g.
/// - currency -> $3.14
/// - currency(symbol: '€') -> €3.14
String? digestL10nOverride({
  required Map<String, ValueFormatter> existingTypes,
  required String locale,
  required String type,
  required Object value,
}) {
  final existingType = existingTypes[type];
  if (existingType != null) {
    // Use existing type formatter directly
    return existingType.format(value);
  }

  final parsed = parseL10nIntermediate(type);
  if (parsed == null) {
    return null;
  }

  // Let's parse the method name and arguments

  if (numberFormatsWithNamedParameters.contains(parsed.methodName)) {
    // named arguments
    final arguments = switch (parsed.arguments) {
      String args => parseArguments(args),
      null => const {},
    };
    final Function formatterBuilder = switch (parsed.methodName) {
      'NumberFormat.compact' => NumberFormat.compact,
      'NumberFormat.compactCurrency' => NumberFormat.compactCurrency,
      'NumberFormat.compactSimpleCurrency' =>
        NumberFormat.compactSimpleCurrency,
      'NumberFormat.compactLong' => NumberFormat.compactLong,
      'NumberFormat.currency' => NumberFormat.currency,
      'NumberFormat.decimalPatternDigits' => NumberFormat.decimalPatternDigits,
      'NumberFormat.decimalPercentPattern' =>
        NumberFormat.decimalPercentPattern,
      'NumberFormat.simpleCurrency' => NumberFormat.simpleCurrency,
      _ => throw UnimplementedError('Unknown formatter: ${parsed.methodName}'),
    };

    final formatter = Function.apply(formatterBuilder, [], {
      ...arguments,
      #locale: locale,
    });

    return formatter.format(value);
  } else {
    // positional arguments
    final argument = switch (parsed.arguments) {
      String args => parseSinglePositionalArgument(args),
      null => null,
    };
    final Function formatterBuilder = switch (parsed.methodName) {
      'NumberFormat.decimalPattern' => NumberFormat.decimalPattern,
      'NumberFormat.percentPattern' => NumberFormat.percentPattern,
      'NumberFormat.scientificPattern' => NumberFormat.scientificPattern,
      'NumberFormat' => _numberFormatBuilder,
      'DateFormat.yM' => DateFormat.yM,
      'DateFormat.yMd' => DateFormat.yMd,
      'DateFormat.Hm' => DateFormat.Hm,
      'DateFormat.Hms' => DateFormat.Hms,
      'DateFormat.jm' => DateFormat.jm,
      'DateFormat.jms' => DateFormat.jms,
      'DateFormat' => _dateFormatBuilder,
      _ => throw UnimplementedError('Unknown formatter: ${parsed.methodName}'),
    };

    final formatter = Function.apply(
      formatterBuilder,
      [
        if (argument != null) argument,
        locale,
      ],
    );
    return formatter.format(value);
  }
}

Map<Symbol, Object> parseArguments(String arguments) {
  final result = <Symbol, Object>{};
  final parts = arguments.split(',');
  for (final part in parts) {
    final keyValue = part.split(':');
    if (keyValue.length != 2) {
      continue;
    }
    final key = keyValue[0].trim();
    final value = keyValue[1].trim();

    if ((value.startsWith("'") && value.endsWith("'")) ||
        (value.startsWith('"') && value.endsWith('"'))) {
      result[Symbol(key)] = value.substring(1, value.length - 1);
    } else {
      final number = num.tryParse(value);
      if (number != null) {
        result[Symbol(key)] = number;
      }
    }
  }
  return result;
}

Object? parseSinglePositionalArgument(String argument) {
  if ((argument.startsWith("'") && argument.endsWith("'") ||
      argument.startsWith('"') && argument.endsWith('"'))) {
    return argument.substring(1, argument.length - 1);
  } else {
    final number = num.tryParse(argument);
    return number;
  }
}

NumberFormat _numberFormatBuilder(String pattern, String locale) {
  return NumberFormat(pattern, locale);
}

DateFormat _dateFormatBuilder(String pattern, String locale) {
  return DateFormat(pattern, locale);
}
