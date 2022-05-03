import 'package:fast_i18n/builder/model/build_config.dart';
import 'package:fast_i18n/builder/model/i18n_locale.dart';
import 'package:fast_i18n/builder/utils/string_extensions.dart';

String getClassNameRoot({
  required String baseName,
  I18nLocale? locale,
  required TranslationClassVisibility visibility,
}) {
  String result = baseName.toCase(CaseStyle.pascal) +
      (locale != null
          ? locale.languageTag.toCaseOfLocale(CaseStyle.pascal)
          : '');
  if (visibility == TranslationClassVisibility.private) result = '_' + result;
  return result;
}

String getClassName({
  required String parentName,
  String childName = '',
  I18nLocale? locale,
}) {
  final String languageTag;
  if (locale != null) {
    languageTag = locale.languageTag.toCaseOfLocale(CaseStyle.pascal);
  } else {
    languageTag = '';
  }
  return parentName + childName.toCase(CaseStyle.pascal) + languageTag;
}
