import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/string_extensions.dart';

String getClassNameRoot(
    {String baseName,
    String locale = '',
    TranslationClassVisibility visibility}) {
  String result = baseName.toCase(KeyCase.pascal) +
      locale.toLowerCase().toCase(KeyCase.pascal);
  if (visibility == TranslationClassVisibility.private) result = '_' + result;
  return result;
}

String getClassName(
    {String parentName, String childName = '', String locale = ''}) {
  return parentName +
      childName.toCase(KeyCase.pascal) +
      locale.toLowerCase().toCase(KeyCase.pascal);
}

// null safety (ns) helpers

String nsOpt(I18nConfig config) {
  return config.nullSafety ? '?' : '';
}

String nsReq(I18nConfig config) {
  return config.nullSafety ? '' : '@';
}

String nsExl(I18nConfig config) {
  return config.nullSafety ? '!' : '';
}

String nsLate(I18nConfig config) {
  return config.nullSafety ? 'late ' : '';
}
