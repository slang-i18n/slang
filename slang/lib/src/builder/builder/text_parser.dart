import 'package:slang/builder/model/enums.dart';
import 'package:slang/src/builder/utils/string_extensions.dart';

class ParseParamResult {
  final String paramName;
  final String paramType;

  ParseParamResult(this.paramName, this.paramType);

  @override
  String toString() =>
      '_ParseParamResult(paramName: $paramName, paramType: $paramType)';
}

ParseParamResult parseParam({
  required String rawParam,
  required String defaultType,
  required CaseStyle? caseStyle,
}) {
  if (rawParam.endsWith(')')) {
    // rich text parameter with default value
    // this will be parsed by another method
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
