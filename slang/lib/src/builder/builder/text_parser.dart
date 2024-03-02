import 'package:slang/builder/model/enums.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';

class ParseParamResult {
  final String paramName;
  final String paramType;

  ParseParamResult(this.paramName, this.paramType);

  @override
  String toString() =>
      'ParseParamResult(paramName: $paramName, paramType: $paramType)';
}

ParseParamResult parseParam({
  required String rawParam,
  required String defaultType,
  required CaseStyle? caseStyle,
}) {
  if (rawParam.endsWith(')')) {
    // rich text parameter with default value
    // this will be parsed by parseParamWithArg
    return ParseParamResult(
      rawParam,
      '',
    );
  }
  final split = rawParam.split(':');
  if (split.length == 1) {
    return ParseParamResult(split[0].toCase(caseStyle), defaultType);
  }
  return ParseParamResult(split[0].trim().toCase(caseStyle), split[1].trim());
}

class ParamWithArg {
  final String paramName;
  final String? arg;

  ParamWithArg(this.paramName, this.arg);

  @override
  String toString() => 'ParamWithArg(paramName: $paramName, arg: $arg)';
}

ParamWithArg parseParamWithArg({
  required String rawParam,
  required CaseStyle? paramCase,
}) {
  final end = rawParam.lastIndexOf(')');
  if (end == -1) {
    return ParamWithArg(rawParam.toCase(paramCase), null);
  }

  final start = rawParam.indexOf('(');
  final parameterName = rawParam.substring(0, start).toCase(paramCase);
  return ParamWithArg(parameterName, rawParam.substring(start + 1, end));
}
