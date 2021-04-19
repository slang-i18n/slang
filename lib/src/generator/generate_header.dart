import 'package:fast_i18n/src/generator/helper.dart';
import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/string_extensions.dart';

void generateHeader(
    StringBuffer buffer, I18nConfig config, List<I18nData> allLocales) {
  // identifiers
  const String baseLocaleVar = '_baseLocale';
  const String currLocaleVar = '_currLocale';
  const String translationsClass = 'Translations';
  const String settingsClass = 'LocaleSettings';
  const String translationProviderKey = '_translationProviderKey';
  const String translationProviderClass = 'TranslationProvider';
  const String translationProviderStateClass = '_TranslationProviderState';
  const String inheritedClass = '_InheritedLocaleData';

  // constants
  final String translateVarInternal = '_${config.translateVariable}';
  final String translateVar = config.translateVariable;
  final String enumName = config.enumName;
  final String baseLocale = config.baseLocale.toLanguageTag();
  final String baseClassName = getClassNameRoot(
      baseName: config.baseName,
      visibility: config.translationClassVisibility,
      locale: config.baseLocale.toLanguageTag());

  buffer.writeln();
  buffer.writeln('// Generated file. Do not edit.');
  buffer.writeln();
  buffer.writeln('import \'package:fast_i18n/fast_i18n.dart\';');
  buffer.writeln('import \'package:flutter/widgets.dart\';');

  // current locale variable
  buffer.writeln();
  buffer.writeln(
      'const $enumName $baseLocaleVar = $enumName.${baseLocale.toEnumConstant()};');
  buffer.writeln('$enumName $currLocaleVar = $baseLocaleVar;');

  // enum
  buffer.writeln();
  buffer.writeln('/// Supported locales, see extension methods below.');
  buffer.writeln('///');
  buffer.writeln('/// Usage:');
  buffer.writeln(
      '/// - LocaleSettings.setLocale($enumName.${baseLocale.toEnumConstant()})');
  buffer.writeln(
      '/// - if (LocaleSettings.currentLocale == $enumName.${baseLocale.toEnumConstant()})');
  buffer.writeln('enum $enumName {');
  for (I18nData locale in allLocales) {
    buffer.writeln(
        '\t${locale.localeTag.toEnumConstant()}, // \'${locale.localeTag}\'${locale.base ? ' (base locale, fallback)' : ''}');
  }
  buffer.writeln('}');

  // t getter
  buffer.writeln();
  buffer.writeln('/// Method A: Simple');
  buffer.writeln('///');
  buffer.writeln('/// No rebuild after locale change.');
  buffer.writeln(
      '/// Translation happens during initialization of the widget (call of $translateVar).');
  buffer.writeln('///');
  buffer.writeln('/// Usage:');
  buffer.writeln('/// String translated = $translateVar.someKey.anotherKey;');
  buffer.writeln(
      '$baseClassName $translateVarInternal = $currLocaleVar.translations;');
  buffer.writeln('$baseClassName get $translateVar => $translateVarInternal;');

  // t getter (advanced)
  buffer.writeln();
  buffer.writeln('/// Method B: Advanced');
  buffer.writeln('///');
  buffer.writeln(
      '/// All widgets using this method will trigger a rebuild when locale changes.');
  buffer.writeln(
      '/// Use this if you have e.g. a settings page where the user can select the locale during runtime.');
  buffer.writeln('///');
  buffer.writeln('/// Step 1:');
  buffer.writeln('/// wrap your App with');
  buffer.writeln('/// TranslationProvider(');
  buffer.writeln('/// \tchild: MyApp()');
  buffer.writeln('/// );');
  buffer.writeln('///');
  buffer.writeln('/// Step 2:');
  buffer.writeln(
      '/// final $translateVar = $translationsClass.of(context); // get $translateVar variable');
  buffer.writeln(
      '/// String translated = $translateVar.someKey.anotherKey; // use $translateVar variable');
  buffer.writeln('class $translationsClass {');
  buffer.writeln('\t$translationsClass._(); // no constructor');
  buffer.writeln();
  buffer.writeln('\tstatic $baseClassName of(BuildContext context) {');
  buffer.writeln(
      '\t\tfinal inheritedWidget = context.dependOnInheritedWidgetOfExactType<_InheritedLocaleData>();');
  buffer.writeln('\t\tif (inheritedWidget == null) {');
  buffer.writeln(
      '\t\t\tthrow(\'Please wrap your app with "TranslationProvider".\');');
  buffer.writeln('\t\t}');
  buffer.writeln('\t\treturn inheritedWidget.translations;');
  buffer.writeln('\t}');
  buffer.writeln('}');

  // settings
  buffer.writeln();
  buffer.writeln('class $settingsClass {');
  buffer.writeln('\t$settingsClass._(); // no constructor');

  buffer.writeln();
  buffer.writeln('\t/// Uses locale of the device, fallbacks to base locale.');
  buffer.writeln('\t/// Returns the locale which has been set.');
  buffer.writeln(
      '\t/// Hint for pre 4.x.x developers: You can access the raw string via LocaleSettings.useDeviceLocale().languageTag');
  buffer.writeln('\tstatic $enumName useDeviceLocale() {');
  buffer.writeln('\t\tString? deviceLocale = FastI18n.getDeviceLocale();');
  buffer.writeln('\t\tif (deviceLocale != null)');
  buffer.writeln('\t\t\treturn setLocaleRaw(deviceLocale);');
  buffer.writeln('\t\telse');
  buffer.writeln('\t\t\treturn setLocale($baseLocaleVar);');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Sets locale');
  buffer.writeln('\t/// Returns the locale which has been set.');
  buffer.writeln('\tstatic $enumName setLocale($enumName locale) {');
  buffer.writeln('\t\t$currLocaleVar = locale;');
  buffer.writeln('\t\t$translateVarInternal = $currLocaleVar.translations;');
  buffer.writeln();
  buffer.writeln('\t\tfinal state = $translationProviderKey.currentState;');
  buffer.writeln('\t\tif (state != null) {');
  buffer.writeln('\t\t\t// force rebuild if TranslationProvider is used');
  buffer.writeln('\t\t\tstate.setLocale($currLocaleVar);');
  buffer.writeln('\t\t}');
  buffer.writeln();
  buffer.writeln('\t\treturn $currLocaleVar;');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Sets locale using string tag (e.g. en_US, de-DE, fr)');
  buffer.writeln('\t/// Fallbacks to base locale.');
  buffer.writeln('\t/// Returns the locale which has been set.');
  buffer.writeln('\tstatic $enumName setLocaleRaw(String locale) {');
  buffer.writeln(
      '\t\tString selectedLocale = FastI18n.selectLocale(locale, supportedLocalesRaw, $baseLocaleVar.languageTag);');
  buffer.writeln('\t\treturn setLocale(selectedLocale.to$enumName()!);');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Gets current locale.');
  buffer.writeln(
      '\t/// Hint for pre 4.x.x developers: You can access the raw string via LocaleSettings.currentLocale.languageTag');
  buffer.writeln('\tstatic $enumName get currentLocale {');
  buffer.writeln('\t\treturn $currLocaleVar;');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Gets base locale.');
  buffer.writeln(
      '\t/// Hint for pre 4.x.x developers: You can access the raw string via LocaleSettings.baseLocale.languageTag');
  buffer.writeln('\tstatic $enumName get baseLocale {');
  buffer.writeln('\t\treturn $baseLocaleVar;');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Gets supported locales in string format.');
  buffer.writeln('\tstatic List<String> get supportedLocalesRaw {');
  buffer.writeln('\t\treturn $enumName.values');
  buffer.writeln('\t\t\t.map((locale) => locale.languageTag)');
  buffer.writeln('\t\t\t.toList();');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln(
      '\t/// Gets supported locales (as Locale objects) with base locale sorted first.');
  buffer.writeln('\tstatic List<Locale> get supportedLocales {');
  buffer.writeln('\t\treturn [');
  for (I18nData locale in allLocales) {
    buffer.write(
        '\t\t\tLocale.fromSubtags(languageCode: \'${locale.locale.language}\'');
    if (locale.locale.script != null)
      buffer.write(', scriptCode: \'${locale.locale.script}\'');
    if (locale.locale.country != null)
      buffer.write(', countryCode: \'${locale.locale.country}\'');
    buffer.writeln('),');
  }
  buffer.writeln('\t\t];');
  buffer.writeln('\t}');

  buffer.writeln('}');

  // enum extension
  buffer.writeln();
  buffer.writeln('// extensions for $enumName');
  buffer.writeln();
  buffer.writeln('extension ${enumName}Extensions on $enumName {');
  buffer.writeln('\t$baseClassName get translations {');
  buffer.writeln('\t\tswitch (this) {');
  for (I18nData locale in allLocales) {
    String className = getClassNameRoot(
        baseName: config.baseName,
        locale: locale.localeTag,
        visibility: config.translationClassVisibility);
    buffer.writeln(
        '\t\t\tcase $enumName.${locale.localeTag.toEnumConstant()}: return $className._instance;');
  }
  buffer.writeln('\t\t}');
  buffer.writeln('\t}');
  buffer.writeln();
  buffer.writeln('\tString get languageTag {');
  buffer.writeln('\t\tswitch (this) {');
  for (I18nData locale in allLocales) {
    buffer.writeln(
        '\t\t\tcase $enumName.${locale.localeTag.toEnumConstant()}: return \'${locale.localeTag}\';');
  }
  buffer.writeln('\t\t}');
  buffer.writeln('\t}');
  buffer.writeln('}');
  buffer.writeln();

  // string extension
  buffer.writeln('extension String${enumName}Extensions on String {');
  buffer.writeln('\t$enumName? to$enumName() {');
  buffer.writeln('\t\tswitch (this) {');
  for (I18nData locale in allLocales) {
    buffer.writeln(
        '\t\t\tcase \'${locale.localeTag}\': return $enumName.${locale.localeTag.toEnumConstant()};');
  }
  buffer.writeln('\t\t\tdefault: return null;');
  buffer.writeln('\t\t}');
  buffer.writeln('\t}');
  buffer.writeln('}');

  buffer.writeln();
  buffer.writeln('// wrappers');

  // TranslationProvider
  buffer.writeln();
  buffer.writeln(
      'GlobalKey<$translationProviderStateClass> $translationProviderKey = new GlobalKey<$translationProviderStateClass>();');
  buffer.writeln();
  buffer.writeln('class $translationProviderClass extends StatefulWidget {');
  buffer.writeln(
      '\t$translationProviderClass({required this.child}) : super(key: $translationProviderKey);');
  buffer.writeln();
  buffer.writeln('\tfinal Widget child;');
  buffer.writeln();
  buffer.writeln('\t@override');
  buffer.writeln(
      '\t$translationProviderStateClass createState() => $translationProviderStateClass();');
  buffer.writeln('}');

  buffer.writeln();
  buffer.writeln(
      'class $translationProviderStateClass extends State<$translationProviderClass> {');
  buffer.writeln('\t$enumName locale = $currLocaleVar;');
  buffer.writeln();
  buffer.writeln('\tvoid setLocale($enumName newLocale) {');
  buffer.writeln('\t\tsetState(() {');
  buffer.writeln('\t\t\tlocale = newLocale;');
  buffer.writeln('\t\t});');
  buffer.writeln('\t}');
  buffer.writeln();
  buffer.writeln('\t@override');
  buffer.writeln('\tWidget build(BuildContext context) {');
  buffer.writeln('\t\treturn $inheritedClass(');
  buffer.writeln('\t\t\tlocale: locale,');
  buffer.writeln('\t\t\tchild: widget.child,');
  buffer.writeln('\t\t);');
  buffer.writeln('\t}');
  buffer.writeln('}');

  // InheritedLocaleData
  buffer.writeln();
  buffer.writeln('class $inheritedClass extends InheritedWidget {');
  buffer.writeln('\tfinal $enumName locale;');
  buffer.writeln(
      '\tfinal $baseClassName translations; // store translations to avoid switch call');
  buffer.writeln(
      '\t$inheritedClass({required this.locale, required Widget child})');
  buffer.writeln(
      '\t\t: translations = locale.translations, super(child: child);');
  buffer.writeln();
  buffer.writeln('\t@override');
  buffer.writeln('\tbool updateShouldNotify($inheritedClass oldWidget) {');
  buffer.writeln('\t\treturn oldWidget.locale != locale;');
  buffer.writeln('\t}');
  buffer.writeln('}');
}
