import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/node.dart';

StringTextNode textNode(
  String raw,
  StringInterpolation interpolation, {
  CaseStyle? paramCase,
  Map<String, Set<String>>? linkParamMap,
}) {
  return StringTextNode(
    path: '',
    rawPath: '',
    modifiers: {},
    raw: raw,
    comment: null,
    interpolation: interpolation,
    paramCase: paramCase,
    shouldEscape: true,
    linkParamMap: linkParamMap,
  );
}

RichTextNode richTextNode(
  String raw,
  StringInterpolation interpolation, {
  CaseStyle? paramCase,
  Map<String, Set<String>>? linkParamMap,
}) {
  return RichTextNode(
    path: '',
    rawPath: '',
    modifiers: {},
    comment: null,
    raw: raw,
    interpolation: interpolation,
    paramCase: paramCase,
    shouldEscape: true,
    linkParamMap: linkParamMap,
  );
}
