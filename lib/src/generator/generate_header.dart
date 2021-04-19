import 'package:fast_i18n/src/generator/helper.dart';
import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:fast_i18n/src/string_extensions.dart';
import 'package:fast_i18n/src/utils.dart';

void generateHeader(
    StringBuffer buffer, I18nConfig config, List<I18nData> allLocales) {
  const String baseLocaleVar = '_baseLocale';
  const String currLocaleVar = '_currLocale';
  const String translationProviderKey = '_translationProviderKey';
  final String translateVarInternal = '_${config.translateVariable}';
  final String baseClassName = getClassNameRoot(
      baseName: config.baseName,
      visibility: config.translationClassVisibility,
      locale: config.baseLocale.toLanguageTag());

  _generateHeaderComment(
      buffer: buffer, config: config, translations: allLocales);

  _generateImports(buffer);

  _generateLocaleVariables(
      buffer: buffer,
      config: config,
      baseLocaleVar: baseLocaleVar,
      currLocaleVar: currLocaleVar);

  _generateEnum(buffer: buffer, config: config, allLocales: allLocales);

  _generateTranslationGetter(
      buffer: buffer,
      config: config,
      baseClassName: baseClassName,
      currLocaleVar: currLocaleVar,
      translateVarInternal: translateVarInternal);

  _generateLocaleSettings(
      buffer: buffer,
      config: config,
      allLocales: allLocales,
      baseLocaleVar: baseLocaleVar,
      currLocaleVar: currLocaleVar,
      translateVarInternal: translateVarInternal,
      translationProviderKey: translationProviderKey);

  _generateExtensions(
      buffer: buffer,
      config: config,
      allLocales: allLocales,
      baseClassName: baseClassName);

  _generateTranslationWrapper(
      buffer: buffer,
      config: config,
      baseClassName: baseClassName,
      translationProviderKey: translationProviderKey,
      currLocaleVar: currLocaleVar);

  _generateHelpers(buffer: buffer, config: config);
}

void _generateHeaderComment(
    {required StringBuffer buffer,
    required I18nConfig config,
    required List<I18nData> translations}) {
  final now = DateTime.now().toUtc();
  final int translationCount = translations.fold(
      0, (prev, curr) => prev + _countTranslations(curr.root));

  buffer.writeln();
  buffer.writeln('/*');
  buffer.writeln(' * Generated file. Do not edit.');
  buffer.writeln(' * ');
  buffer.writeln(' * Locales: ${translations.length}');
  buffer.writeln(
      ' * Strings: $translationCount ${translations.length != 1 ? '(${(translationCount / translations.length).toStringAsFixed(1)} per locale)' : ''}');
  buffer.writeln(' * ');
  buffer.writeln(
      ' * Built on ${now.year.toString()}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} UTC');
  buffer.writeln(' */');
}

void _generateImports(StringBuffer buffer) {
  buffer.writeln();
  buffer.writeln('import \'package:flutter/widgets.dart\';');
}

void _generateLocaleVariables(
    {required StringBuffer buffer,
    required I18nConfig config,
    required String baseLocaleVar,
    required String currLocaleVar}) {
  final String enumName = config.enumName;
  final String baseLocale = config.baseLocale.toLanguageTag();

  buffer.writeln();
  buffer.writeln(
      'const $enumName $baseLocaleVar = $enumName.${baseLocale.toEnumConstant()};');
  buffer.writeln('$enumName $currLocaleVar = $baseLocaleVar;');
}

void _generateEnum(
    {required StringBuffer buffer,
    required I18nConfig config,
    required List<I18nData> allLocales}) {
  final String enumName = config.enumName;
  final String baseLocale = config.baseLocale.toLanguageTag();

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
}

void _generateTranslationGetter(
    {required StringBuffer buffer,
    required I18nConfig config,
    required String baseClassName,
    required String currLocaleVar,
    required String translateVarInternal}) {
  const String translationsClass = 'Translations';
  final String translateVar = config.translateVariable;

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
}

void _generateLocaleSettings(
    {required StringBuffer buffer,
    required I18nConfig config,
    required List<I18nData> allLocales,
    required String baseLocaleVar,
    required String currLocaleVar,
    required String translateVarInternal,
    required String translationProviderKey}) {
  const String settingsClass = 'LocaleSettings';
  final String enumName = config.enumName;

  buffer.writeln();
  buffer.writeln('class $settingsClass {');
  buffer.writeln('\t$settingsClass._(); // no constructor');

  buffer.writeln();
  buffer.writeln('\t/// Uses locale of the device, fallbacks to base locale.');
  buffer.writeln('\t/// Returns the locale which has been set.');
  buffer.writeln(
      '\t/// Hint for pre 4.x.x developers: You can access the raw string via LocaleSettings.useDeviceLocale().languageTag');
  buffer.writeln('\tstatic $enumName useDeviceLocale() {');
  buffer.writeln(
      '\t\tString? deviceLocale = WidgetsBinding.instance?.window.locale.toLanguageTag();');
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
  buffer.writeln('\tstatic $enumName setLocaleRaw(String localeRaw) {');
  buffer.writeln('\t\tfinal selected = _selectLocale(localeRaw);');
  buffer.writeln('\t\treturn setLocale(selected ?? $baseLocaleVar);');
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
}

void _generateExtensions(
    {required StringBuffer buffer,
    required I18nConfig config,
    required List<I18nData> allLocales,
    required String baseClassName}) {
  final String enumName = config.enumName;

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

  // string extension
  buffer.writeln();
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
}

void _generateTranslationWrapper(
    {required StringBuffer buffer,
    required I18nConfig config,
    required String baseClassName,
    required String translationProviderKey,
    required String currLocaleVar}) {
  const String translationProviderClass = 'TranslationProvider';
  const String translationProviderStateClass = '_TranslationProviderState';
  const String inheritedClass = '_InheritedLocaleData';
  final String enumName = config.enumName;

  // TranslationProvider
  buffer.writeln();
  buffer.writeln('// wrappers');
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

void _generateHelpers(
    {required StringBuffer buffer, required I18nConfig config}) {
  final enumName = config.enumName;
  buffer.writeln();
  buffer.writeln('// helpers');
  buffer.writeln();
  buffer.writeln(
      'final _localeRegex = RegExp(r\'^${Utils.LOCALE_REGEX_RAW}\$\');');
  buffer.writeln('$enumName? _selectLocale(String localeRaw) {');
  buffer.writeln('\tfinal match = _localeRegex.firstMatch(localeRaw);');
  buffer.writeln('\tAppLocale? selected;');
  buffer.writeln('\tif (match != null) {');
  buffer.writeln('\t\tfinal language = match.group(1);');
  buffer.writeln();
  buffer.writeln('\t\t// match exactly');
  buffer.writeln('\t\tselected = $enumName.values');
  buffer.writeln('\t\t\t.cast<$enumName?>()');
  buffer.writeln(
      '\t\t\t.firstWhere((supported) => supported?.languageTag == localeRaw, orElse: () => null);');
  buffer.writeln();
  buffer.writeln('\t\tif (selected == null && language != null) {');
  buffer.writeln('\t\t\t// match language');
  buffer.writeln('\t\t\tselected = $enumName.values');
  buffer.writeln('\t\t\t\t.cast<$enumName?>()');
  buffer.writeln(
      '\t\t\t\t.firstWhere((supported) => supported?.languageTag.startsWith(language) == true, orElse: () => null);');
  buffer.writeln('\t\t}');
  buffer.writeln('\t}');
  buffer.writeln('\treturn selected;');
  buffer.writeln('}');
}

int _countTranslations(Node node) {
  if (node is TextNode) {
    return 1;
  } else if (node is ListNode) {
    int sum = 0;
    for (Node entry in node.entries) {
      sum += _countTranslations(entry);
    }
    return sum;
  } else if (node is ObjectNode) {
    int sum = 0;
    for (Node entry in node.entries.values) {
      sum += _countTranslations(entry);
    }
    return sum;
  } else {
    return 0;
  }
}
