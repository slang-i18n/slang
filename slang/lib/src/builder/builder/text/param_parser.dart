import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';

class ParseParamResult {
  final String paramName;
  final String paramType;

  const ParseParamResult(this.paramName, this.paramType);

  @override
  String toString() =>
      'ParseParamResult(paramName: $paramName, paramType: $paramType)';
}

/// Parses a parameter string.
/// E.g. `p: int` -> `ParseParamResult(paramName: 'p', paramType: 'int')`
ParseParamResult parseParam({
  required String rawParam,
  required String defaultType,
  required CaseStyle? caseStyle,
}) {
  final colonIndex = rawParam.indexOf(':');
  if (colonIndex == -1) {
    return ParseParamResult(rawParam.toCase(caseStyle), defaultType);
  }
  return ParseParamResult(
    rawParam.substring(0, colonIndex).trim().toCase(caseStyle),
    rawParam.substring(colonIndex + 1).trim(),
  );
}

class ParamWithArg {
  final String paramName;
  final String? arg;

  const ParamWithArg(this.paramName, this.arg);

  @override
  String toString() => 'ParamWithArg(paramName: $paramName, arg: $arg)';
}

ParamWithArg parseParamWithArg({
  required String rawParam,
  required CaseStyle? paramCase,
}) {
  final colonIndex = rawParam.indexOf(':');
  final start = rawParam.indexOf('(');
  if (colonIndex != -1 && (start == -1 || colonIndex < start)) {
    // ignore type for rich text
    rawParam = rawParam.substring(0, colonIndex);
  }

  if (start == -1) {
    return ParamWithArg(rawParam.toCase(paramCase), null);
  }

  final end = rawParam.lastIndexOf(')');
  final parameterName = rawParam.substring(0, start).toCase(paramCase);
  return ParamWithArg(parameterName, rawParam.substring(start + 1, end));
}
