import 'package:slang/src/builder/builder/translation_model_builder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/node.dart';

final _locale = I18nLocale(language: 'en');

StringTextNode textNode(
  String raw,
  StringInterpolation interpolation, {
  CaseStyle? paramCase,
  Map<String, Set<String>>? linkParamMap,
  Map<String, FormatTypeInfo> formatters = const {},
}) {
  return StringTextNode(
    path: '',
    rawPath: '',
    modifiers: {},
    locale: _locale,
    types: formatters,
    raw: raw,
    comment: null,
    interpolation: interpolation,
    paramCase: paramCase,
    shouldEscape: true,
    handleTypes: true,
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
    types: {},
    raw: raw,
    interpolation: interpolation,
    paramCase: paramCase,
    shouldEscape: true,
    handleTypes: true,
    linkParamMap: linkParamMap,
  );
}
