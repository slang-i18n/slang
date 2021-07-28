import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/string_extensions.dart';

String getClassNameRoot(
    {required String baseName,
    String locale = '',
    required TranslationClassVisibility visibility}) {
  String result = baseName.toCase(KeyCase.pascal) +
      locale.toLowerCase().toCase(KeyCase.pascal);
  if (visibility == TranslationClassVisibility.private) result = '_' + result;
  return result;
}

String getClassName(
    {required String parentName, String childName = '', I18nLocale? locale}) {
  return parentName +
      childName.toCase(KeyCase.pascal) +
      (locale != null
          ? locale.languageTag.toLowerCase().toCase(KeyCase.pascal)
          : '');
}
