import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/node.dart';

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
