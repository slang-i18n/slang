import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/node.dart';

final _locale = I18nLocale(language: 'en');

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
    locale: _locale,
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
    locale: _locale,
    raw: raw,
    interpolation: interpolation,
    paramCase: paramCase,
    shouldEscape: true,
    linkParamMap: linkParamMap,
  );
}
