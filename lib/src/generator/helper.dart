import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/utils/string_extensions.dart';

String getClassNameRoot({
  required String baseName,
  String locale = '',
  required TranslationClassVisibility visibility,
}) {
  String result = baseName.toCase(CaseStyle.pascal) +
      locale.toLowerCase().toCase(CaseStyle.pascal);
  if (visibility == TranslationClassVisibility.private) result = '_' + result;
  return result;
}

String getClassName({
  required String parentName,
  String childName = '',
  I18nLocale? locale,
}) {
  return parentName +
      childName.toCase(CaseStyle.pascal) +
      (locale != null
          ? locale.languageTag.toLowerCase().toCase(CaseStyle.pascal)
          : '');
}
