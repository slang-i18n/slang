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
