import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/node.dart';

StringTextNode textNode(
  String raw,
  StringInterpolation interpolation, [
  CaseStyle? paramCase,
]) {
  return StringTextNode(
    path: '',
    rawPath: '',
    raw: raw,
    comment: null,
    interpolation: interpolation,
    paramCase: paramCase,
  );
}

RichTextNode richTextNode(
  String raw,
  StringInterpolation interpolation, [
  CaseStyle? paramCase,
]) {
  return RichTextNode(
    path: '',
    rawPath: '',
    comment: null,
    raw: raw,
    interpolation: interpolation,
    paramCase: paramCase,
  );
}
