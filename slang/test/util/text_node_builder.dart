import 'package:slang/builder/model/build_config.dart';
import 'package:slang/builder/model/node.dart';

StringTextNode textNode(
  String raw,
  StringInterpolation interpolation, [
  CaseStyle? paramCase,
]) {
  return StringTextNode(
    path: '',
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
    comment: null,
    raw: raw,
    interpolation: interpolation,
    paramCase: paramCase,
  );
}
