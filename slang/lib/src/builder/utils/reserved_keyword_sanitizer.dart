import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';

/// Converts a reserved keyword to a valid identifier by
/// adding a prefix to it.
/// It also applies the specified [caseStyle] to the identifier.
String sanitizeReservedKeyword({
  required String name,
  required String prefix,
  required CaseStyle? sanitizeCaseStyle,
  required CaseStyle? defaultCaseStyle,
  bool sanitize = true,
}) {
  if (sanitize &&
      (_reservedKeyWords.contains(name) ||
          RegexUtils.startsWithNumber.hasMatch(name))) {
    if (sanitizeCaseStyle != null) {
      // need to add space so that it treats the prefix as a separate word
      return '$prefix $name'.toCase(sanitizeCaseStyle);
    } else {
      return '$prefix$name';
    }
  }
  return name.toCase(defaultCaseStyle);
}

/// Reserved keywords that are not allowed to be used as identifiers.
/// Some reserved keywords are allowed to be used as identifiers! For example,
/// abstract, await, yield, etc.
/// See https://dart.dev/language/keywords
const _reservedKeyWords = {
  'assert',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'else',
  'enum',
  'extends',
  'false',
  'final',
  'finally',
  'for',
  'if',
  'in',
  'is',
  'new',
  'null',
  'rethrow',
  'return',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'var',
  'void',
  'with',
  'while',
};
