import 'package:collection/collection.dart';
import 'package:fast_i18n/src/generator/helper.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:fast_i18n/src/model/pluralization.dart';
import 'package:fast_i18n/src/utils/path_utils.dart';
import 'package:fast_i18n/src/utils/string_extensions.dart';

String generateHeader(
  I18nConfig config,
  List<I18nData> allLocales,
) {
  const String baseLocaleVar = '_baseLocale';
  const String currLocaleVar = '_currLocale';
  const String translationProviderKey = '_translationProviderKey';
  final String translateVarInternal = '_${config.translateVariable}';
  final String baseClassName = getClassNameRoot(
      baseName: config.baseName,
      visibility: config.translationClassVisibility,
      locale: config.baseLocale);
  const String pluralResolverType = 'PluralResolver';
  const String pluralResolverMapCardinal = '_pluralResolversCardinal';
  const String pluralResolverMapOrdinal = '_pluralResolversOrdinal';

  final buffer = StringBuffer();

  _generateHeaderComment(
    buffer: buffer,
    config: config,
    translations: allLocales,
    now: DateTime.now().toUtc(),
  );

  _generateImports(config, buffer);

  if (config.outputFormat == OutputFormat.multipleFiles) {
    _generateParts(
      buffer: buffer,
      config: config,
      locales: allLocales,
    );
  }

  _generateLocaleVariables(
    buffer: buffer,
    config: config,
    baseLocaleVar: baseLocaleVar,
    currLocaleVar: currLocaleVar,
  );

  _generateEnum(
    buffer: buffer,
    config: config,
    allLocales: allLocales,
  );

  if (config.renderLocaleHandling) {
    _generateTranslationGetter(
      buffer: buffer,
      config: config,
      baseClassName: baseClassName,
      currLocaleVar: currLocaleVar,
      translateVarInternal: translateVarInternal,
    );

    _generateLocaleSettings(
      buffer: buffer,
      config: config,
      allLocales: allLocales,
      baseLocaleVar: baseLocaleVar,
      currLocaleVar: currLocaleVar,
      translateVarInternal: translateVarInternal,
      translationProviderKey: translationProviderKey,
      pluralResolverType: pluralResolverType,
      pluralResolverCardinal: pluralResolverMapCardinal,
      pluralResolverOrdinal: pluralResolverMapOrdinal,
    );
  }

  // _generateUtilClass(
  //   buffer: buffer,
  //   config: config,
  //   baseLocaleVar: baseLocaleVar,
  // );

  _generateContextEnums(buffer: buffer, config: config);

  _generateInterfaces(buffer: buffer, config: config);

  if (config.renderLocaleHandling) {
    _generateInstances(
      buffer: buffer,
      config: config,
      allLocales: allLocales,
      baseClassName: baseClassName,
    );
  }

  _generateExtensions(
    buffer: buffer,
    config: config,
    allLocales: allLocales,
    baseClassName: baseClassName,
  );

  if (config.renderLocaleHandling) {
    _generateTranslationWrapper(
      buffer: buffer,
      config: config,
      baseClassName: baseClassName,
      translationProviderKey: translationProviderKey,
      currLocaleVar: currLocaleVar,
    );
  }

  _generatePluralResolvers(
    buffer: buffer,
    config: config,
    pluralResolverType: pluralResolverType,
    pluralResolverCardinal: pluralResolverMapCardinal,
    pluralResolverOrdinal: pluralResolverMapOrdinal,
  );

  // _generateHelpers(
  //   buffer: buffer,
  //   config: config,
  // );

  return buffer.toString();
}

void _generateHeaderComment({
  required StringBuffer buffer,
  required I18nConfig config,
  required List<I18nData> translations,
  required DateTime now,
}) {
  final int translationCount = translations.fold(
      0, (prev, curr) => prev + _countTranslations(curr.root));

  buffer.writeln();
  buffer.writeln('/*');
  buffer.writeln(' * Generated file. Do not edit.');
  buffer.writeln(' *');
  buffer.writeln(' * Locales: ${translations.length}');
  buffer.writeln(
      ' * Strings: $translationCount ${translations.length != 1 ? '(${(translationCount / translations.length).toStringAsFixed(1)} per locale)' : ''}');

  if (config.renderTimestamp) {
    buffer.writeln(' *');
    buffer.writeln(
        ' * Built on ${now.year.toString()}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} UTC');
  }

  buffer.writeln(' */');
}

void _generateImports(I18nConfig config, StringBuffer buffer) {
  buffer.writeln();
  if (config.dartOnly) {
    buffer.writeln('import \'package:fast_i18n_dart/fast_i18n_dart.dart\';');
  } else {
    buffer.writeln(
        'import \'package:fast_i18n_flutter/fast_i18n_flutter.dart\';');
  }
  // buffer.writeln('import \'package:flutter/widgets.dart\';');
}

void _generateParts({
  required StringBuffer buffer,
  required I18nConfig config,
  required List<I18nData> locales,
}) {
  buffer.writeln();
  for (final locale in locales) {
    buffer.writeln(
        'part \'${BuildResultPaths.localePath(outputPath: config.baseName, locale: locale.locale, pathSeparator: 'not needed')}\';');
  }
  if (config.renderFlatMap) {
    buffer.writeln(
        'part \'${BuildResultPaths.flatMapPath(outputPath: config.baseName, pathSeparator: 'not needed')}\';');
  }
}

void _generateLocaleVariables({
  required StringBuffer buffer,
  required I18nConfig config,
  required String baseLocaleVar,
  required String currLocaleVar,
}) {
  final String enumName = config.enumName;

  buffer.writeln();
  buffer.writeln(
      'const $enumName $baseLocaleVar = $enumName.${config.baseLocale.enumConstant};');

  // if (config.renderLocaleHandling) {
  //   buffer.writeln('$enumName $currLocaleVar = $baseLocaleVar;');
  // }
}

void _generateEnum({
  required StringBuffer buffer,
  required I18nConfig config,
  required List<I18nData> allLocales,
}) {
  final String enumName = config.enumName;
  final String baseLocaleEnumConstant =
      '$enumName.${config.baseLocale.enumConstant}';

  buffer.writeln();
  buffer.writeln('/// Supported locales, see extension methods below.');
  buffer.writeln('///');
  buffer.writeln('/// Usage:');
  buffer.writeln(
      '/// - LocaleSettings.setLocale($baseLocaleEnumConstant) // set locale');
  buffer.writeln(
      '/// - Locale locale = $baseLocaleEnumConstant.flutterLocale // get flutter locale from enum');
  buffer.writeln(
      '/// - if (LocaleSettings.currentLocale == $baseLocaleEnumConstant) // locale check');

  buffer.writeln('enum $enumName {');
  for (I18nData locale in allLocales) {
    buffer.writeln('\t${locale.locale.enumConstant},');
  }
  buffer.writeln('}');

  buffer.writeln();
  buffer.writeln('class AppLocaleIdConst {');
  for (I18nData locale in allLocales) {
    buffer.writeln(
        '\t// \'${locale.locale.languageTag}\'${locale.base ? ' (base locale, fallback)' : ''}');
    buffer.write('\tstatic const ${locale.locale.enumConstant} = AppLocaleId(');
    buffer.write('languageCode: \'${locale.locale.language}\'');
    if (locale.locale.script != null) {
      buffer.write(', ');
      buffer.write('scriptCode: \'${locale.locale.script}\', ');
    }
    if (locale.locale.country != null) {
      buffer.write(', ');
      buffer.write('countryCode: \'${locale.locale.country}\'');
    }
    buffer.writeln(');');
  }
  buffer.writeln('');
  buffer.write('\tstatic const values = [');
  buffer
      .write(allLocales.map((locale) => locale.locale.enumConstant).join(', '));
  buffer.writeln('];');
  buffer.writeln('}');

  buffer.writeln();
  buffer.writeln('extension ExtAppLocale on AppLocale {');
  buffer.writeln('\tAppLocaleId get localeId {');
  buffer.writeln('\t\tswitch (this) {');
  for (I18nData locale in allLocales) {
    buffer.writeln(
        '\t\t\tcase AppLocale.${locale.locale.enumConstant}: return AppLocaleIdConst.${locale.locale.enumConstant};');
  }
  buffer.writeln('\t\t}');
  buffer.writeln('\t}');
  buffer.writeln('}');

  buffer.writeln();
  buffer.writeln('extension ExtAppLocaleId on AppLocaleId {');
  buffer.writeln('\tAppLocale get locale {');
  for (I18nData locale in allLocales) {
    buffer.writeln(
        '\t\tif (this == AppLocaleIdConst.${locale.locale.enumConstant}) return AppLocale.${locale.locale.enumConstant};');
  }
  buffer.writeln("\t\tthrow Exception('Unsupported locale id: \$this');");
  buffer.writeln('\t}');
  buffer.writeln('}');
}

void _generateTranslationGetter({
  required StringBuffer buffer,
  required I18nConfig config,
  required String baseClassName,
  required String currLocaleVar,
  required String translateVarInternal,
}) {
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
  buffer.writeln('/// String a = $translateVar.someKey.anotherKey;');
  if (config.renderFlatMap) {
    buffer.writeln(
        '/// String b = $translateVar[\'someKey.anotherKey\']; // Only for edge cases!');
  }
  buffer.writeln(
      '$baseClassName get $translateVar => LocaleSettings.instance.currentLocale.translations;');

  // t getter (advanced)
  if (!config.dartOnly) {
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
        '/// final $translateVar = $translationsClass.of(context); // Get $translateVar variable.');
    buffer.writeln(
        '/// String a = $translateVar.someKey.anotherKey; // Use $translateVar variable.');
    if (config.renderFlatMap) {
      buffer.writeln(
          '/// String b = $translateVar[\'someKey.anotherKey\']; // Only for edge cases!');
    }
    buffer.writeln('class $translationsClass {');
    buffer.writeln('\t$translationsClass._(); // no constructor');
    buffer.writeln();
    buffer.writeln(
        '\tstatic $baseClassName of(BuildContext context) => InheritedLocaleData.of(context).translations;');
    // buffer.writeln(
    //     '\t\tfinal inheritedWidget = context.dependOnInheritedWidgetOfExactType<_InheritedLocaleData>();');
    // buffer.writeln('\t\tif (inheritedWidget == null) {');
    // buffer.writeln(
    //     '\t\t\tthrow \'Please wrap your app with "TranslationProvider".\';');
    // buffer.writeln('\t\t}');
    // buffer.writeln('\t\treturn inheritedWidget.translations;');
    // buffer.writeln('\t}');
    buffer.writeln('}');
  }
}

void _generateLocaleSettings({
  required StringBuffer buffer,
  required I18nConfig config,
  required List<I18nData> allLocales,
  required String baseLocaleVar,
  required String currLocaleVar,
  required String translateVarInternal,
  required String translationProviderKey,
  required String pluralResolverType,
  required String pluralResolverCardinal,
  required String pluralResolverOrdinal,
}) {
  const String settingsClass = 'LocaleSettings';
  final String enumName = config.enumName;
  // final String utilsClass = '${enumName}Utils';

  buffer.writeln();
  buffer.writeln('class $settingsClass extends BaseLocaleSettings {');
  buffer.writeln('\t$settingsClass._() : super(');
  buffer.writeln('\t\tbaseLocale: _baseLocale.localeId,');
  buffer.writeln(
      '\t\tlocaleValues: AppLocale.values.map((e) => e.localeId).toList(),');
  buffer.writeln('\t);');
  buffer.writeln();
  buffer.writeln('\tstatic final instance = $settingsClass._();');
  buffer.writeln();
  buffer.writeln('\tAppLocale get currentLocale => currentLocaleId.locale;');

  // buffer.writeln();
  // buffer.writeln('\t/// Uses locale of the device, fallbacks to base locale.');
  // buffer.writeln('\t/// Returns the locale which has been set.');
  // buffer.writeln('\tstatic $enumName useDeviceLocale() {');
  // buffer.writeln('\t\tfinal locale = $utilsClass.findDeviceLocale();');
  // buffer.writeln('\t\treturn setLocale(locale);');
  // buffer.writeln('\t}');
  //
  // buffer.writeln();
  // buffer.writeln('\t/// Sets locale');
  // buffer.writeln('\t/// Returns the locale which has been set.');
  // buffer.writeln('\tstatic $enumName setLocale($enumName locale) {');
  // buffer.writeln('\t\t$currLocaleVar = locale;');
  // buffer.writeln();
  // buffer.writeln('\t\tif (WidgetsBinding.instance != null) {');
  // buffer.writeln('\t\t\t// force rebuild if TranslationProvider is used');
  // buffer.writeln(
  //     '\t\t\t$translationProviderKey.currentState?.setLocale($currLocaleVar);');
  // buffer.writeln('\t\t}');
  // buffer.writeln();
  // buffer.writeln('\t\treturn $currLocaleVar;');
  // buffer.writeln('\t}');
  //
  // buffer.writeln();
  // buffer.writeln('\t/// Sets locale using string tag (e.g. en_US, de-DE, fr)');
  // buffer.writeln('\t/// Fallbacks to base locale.');
  // buffer.writeln('\t/// Returns the locale which has been set.');
  // buffer.writeln('\tstatic $enumName setLocaleRaw(String rawLocale) {');
  // buffer.writeln('\t\tfinal locale = $utilsClass.parse(rawLocale);');
  // buffer.writeln('\t\treturn setLocale(locale);');
  // buffer.writeln('\t}');
  //
  // buffer.writeln();
  // buffer.writeln('\t/// Gets current locale.');
  // buffer.writeln('\tstatic $enumName get currentLocale {');
  // buffer.writeln('\t\treturn $currLocaleVar;');
  // buffer.writeln('\t}');
  //
  // buffer.writeln();
  // buffer.writeln('\t/// Gets base locale.');
  // buffer.writeln('\tstatic $enumName get baseLocale {');
  // buffer.writeln('\t\treturn $baseLocaleVar;');
  // buffer.writeln('\t}');
  //
  // buffer.writeln();
  // buffer.writeln('\t/// Gets supported locales in string format.');
  // buffer.writeln('\tstatic List<String> get supportedLocalesRaw {');
  // buffer.writeln('\t\treturn $enumName.values');
  // buffer.writeln('\t\t\t.map((locale) => locale.languageTag)');
  // buffer.writeln('\t\t\t.toList();');
  // buffer.writeln('\t}');
  //
  // buffer.writeln();
  // buffer.writeln(
  //     '\t/// Gets supported locales (as Locale objects) with base locale sorted first.');
  // buffer.writeln('\tstatic List<Locale> get supportedLocales {');
  // buffer.writeln('\t\treturn $enumName.values');
  // buffer.writeln('\t\t\t.map((locale) => locale.flutterLocale)');
  // buffer.writeln('\t\t\t.toList();');
  // buffer.writeln('\t}');

  if (config.hasPlurals()) {
    buffer.writeln();
    buffer.writeln('\t/// Sets plural resolvers.');
    buffer.writeln(
        '\t/// See https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html');
    buffer.writeln(
        '\t/// See https://github.com/Tienisto/flutter-fast-i18n/blob/master/lib/src/model/pluralization_resolvers.dart');
    buffer.writeln(
        '\t/// Either specify [language], or [locale]. Locale has precedence.');
    buffer.write('\t/// Rendered Resolvers: [');
    final renderedResolvers = config.getRenderedPluralResolvers().toList();
    for (int i = 0; i < renderedResolvers.length; i++) {
      if (i != 0) buffer.write(', ');
      buffer.write('\'${renderedResolvers[i]}\'');
    }
    buffer.writeln(']');

    final missing = config.unsupportedPluralLanguages.toList();
    if (missing.isNotEmpty) {
      buffer.write('\t/// You must set these: [');
      for (int i = 0; i < missing.length; i++) {
        if (i != 0) buffer.write(', ');
        buffer.write('\'${missing[i]}\'');
      }
      buffer.writeln(']');
    }

    buffer.writeln(
        '\tstatic void setPluralResolver({String? language, $enumName? locale, $pluralResolverType? cardinalResolver, $pluralResolverType? ordinalResolver}) {');
    buffer.writeln('\t\tfinal List<$enumName> locales;');
    buffer.writeln('\t\tif (locale != null) {');
    buffer.writeln('\t\t\tlocales = [locale];');
    buffer.writeln('\t\t} else {');
    buffer.writeln('\t\t\tswitch (language) {');
    allLocales.groupListsBy((l) => l.locale.language).forEach((key, value) {
      buffer.writeln('\t\t\t\tcase \'$key\':');
      buffer.writeln(
          '\t\t\t\t\tlocales = [${value.map((l) => '$enumName.${l.locale.enumConstant}').join(',')}];');
      buffer.writeln('\t\t\t\t\tbreak;');
    });
    buffer.writeln('\t\t\t\tdefault:');
    buffer.writeln('\t\t\t\t\tlocales = [];');
    buffer.writeln('\t\t\t}');
    buffer.writeln('\t\t}');

    buffer.writeln('\t\tfor (final curr in locales) {');
    buffer.writeln(
        '\t\t\t_translationsMap[curr] = curr.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);');
    buffer.writeln('\t\t}');

    buffer.writeln('\t}');
  }

  buffer.writeln('}');
}

// void _generateUtilClass({
//   required StringBuffer buffer,
//   required I18nConfig config,
//   required String baseLocaleVar,
// }) {
//   final String enumName = config.enumName;
//   final String utilsClass = '${enumName}Utils';
//
//   buffer.writeln();
//   buffer.writeln('/// Provides utility functions without any side effects.');
//   buffer.writeln('class $utilsClass {');
//   buffer.writeln('\t$utilsClass._(); // no constructor');
//
//   buffer.writeln();
//   buffer.writeln('\t/// Returns the locale of the device as the enum type.');
//   buffer.writeln('\t/// Fallbacks to base locale.');
//   buffer.writeln('\tstatic $enumName findDeviceLocale() {');
//   buffer.writeln(
//       '\t\tfinal String? deviceLocale = WidgetsBinding.instance?.window.locale.toLanguageTag();');
//   buffer.writeln('\t\tif (deviceLocale != null) {');
//   buffer.writeln('\t\t\tfinal typedLocale = FastI18nDartInternalUtil.selectLocale(deviceLocale);');
//   buffer.writeln('\t\t\tif (typedLocale != null) {');
//   buffer.writeln('\t\t\t\treturn typedLocale;');
//   buffer.writeln('\t\t\t}');
//   buffer.writeln('\t\t}');
//   buffer.writeln('\t\treturn $baseLocaleVar;');
//   buffer.writeln('\t}');
//
//   buffer.writeln();
//   buffer.writeln('\t/// Returns the enum type of the raw locale.');
//   buffer.writeln('\t/// Fallbacks to base locale.');
//   buffer.writeln('\tstatic $enumName parse(String rawLocale) {');
//   buffer.writeln('\t\treturn FastI18nDartInternalUtil.selectLocale(rawLocale) ?? $baseLocaleVar;');
//   buffer.writeln('\t}');
//
//   buffer.writeln('}');
// }

void _generateContextEnums({
  required StringBuffer buffer,
  required I18nConfig config,
}) {
  buffer.writeln();
  buffer.writeln('// context enums');

  for (final contextType in config.contexts) {
    buffer.writeln();
    buffer.writeln('enum ${contextType.enumName} {');
    for (final enumValue in contextType.enumValues) {
      buffer.writeln('\t$enumValue,');
    }
    buffer.writeln('}');
  }
}

void _generateInterfaces({
  required StringBuffer buffer,
  required I18nConfig config,
}) {
  buffer.writeln();
  buffer.writeln('// interfaces generated as mixins');

  for (final interface in config.interface) {
    buffer.writeln();
    buffer.writeln('mixin ${interface.name} {');
    for (final attribute in interface.attributes) {
      final nullable = attribute.optional ? '?' : '';
      final defaultNull = attribute.optional ? ' => null' : '';
      if (attribute.parameters.isEmpty) {
        // simple text nodes or others
        buffer.writeln(
            '\t${attribute.returnType}$nullable get ${attribute.attributeName}$defaultNull;');
      } else {
        // this should be a text node
        buffer.write(
            '\t${attribute.returnType}$nullable ${attribute.attributeName}({');
        bool first = true;
        for (final param in attribute.parameters) {
          if (!first) buffer.write(', ');
          buffer.write('required ${param.type} ${param.parameterName}');
          first = false;
        }
        buffer.writeln('})$defaultNull;');
      }
    }
    buffer.writeln('}');
  }
}

void _generateInstances({
  required StringBuffer buffer,
  required I18nConfig config,
  required List<I18nData> allLocales,
  required String baseClassName,
}) {
  buffer.writeln();
  buffer.writeln('// translation instances');
  buffer.writeln();

  buffer.writeln('late final _translationsMap = <AppLocale, $baseClassName>{');
  for (I18nData locale in allLocales) {
    final className = getClassNameRoot(
      baseName: config.baseName,
      locale: locale.locale,
      visibility: config.translationClassVisibility,
    );
    buffer.writeln(
        '\tAppLocale.${locale.locale.languageTag}: $className.build(),');
    // buffer.writeln(
    //     'late $className _translations${locale.locale.languageTag.toCaseOfLocale(CaseStyle.pascal)} = $className.build();');
  }
  buffer.writeln('};');
}

void _generateExtensions({
  required StringBuffer buffer,
  required I18nConfig config,
  required List<I18nData> allLocales,
  required String baseClassName,
}) {
  final String enumName = config.enumName;

  buffer.writeln();
  buffer.writeln('// extensions for $enumName');
  buffer.writeln();
  buffer.writeln('extension ${enumName}Extensions on AppLocale {');

  if (config.renderLocaleHandling) {
    buffer.writeln();
    buffer.writeln(
        '\t/// Gets the translation instance managed by this library.');
    buffer.writeln('\t/// [TranslationProvider] is using this instance.');
    buffer.writeln('\t/// The plural resolvers are set via [LocaleSettings].');
    buffer.writeln('\t$baseClassName get translations {');
    // buffer.writeln('\t\tswitch (this) {');
    // for (I18nData locale in allLocales) {
    //   buffer.writeln(
    //       '\t\t\tcase $enumName.${locale.locale.enumConstant}: return _translations${locale.locale.languageTag.toCaseOfLocale(CaseStyle.pascal)};');
    // }
    // buffer.writeln('\t\t}');
    buffer.writeln('\t\treturn _translationsMap[this]!;');
    buffer.writeln('\t}');
  }

  buffer.writeln();
  buffer.writeln('\t/// Gets a new translation instance.');
  if (config.renderLocaleHandling) {
    buffer.writeln('\t/// [LocaleSettings] has no effect here.');
  }
  buffer.writeln('\t/// Suitable for dependency injection and unit tests.');
  buffer.writeln('\t///');
  buffer.writeln('\t/// Usage:');
  buffer.writeln(
      '\t/// final t = AppLocale.${config.baseLocale.enumConstant}.build(); // build');
  buffer.writeln('\t/// String a = t.my.path; // access');
  if (config.hasPlurals()) {
    buffer.writeln(
        '\t$baseClassName build({PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) {');
  } else {
    buffer.writeln('\t$baseClassName build() {');
  }

  buffer.writeln('\t\tswitch (this) {');
  for (I18nData locale in allLocales) {
    final className = getClassNameRoot(
      baseName: config.baseName,
      locale: locale.locale,
      visibility: config.translationClassVisibility,
    );

    if (config.hasPlurals()) {
      buffer.writeln(
          '\t\t\tcase $enumName.${locale.locale.enumConstant}: return $className.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);');
    } else {
      buffer.writeln(
          '\t\t\tcase $enumName.${locale.locale.enumConstant}: return $className.build();');
    }
  }
  buffer.writeln('\t\t}');
  buffer.writeln('\t}');

  // buffer.writeln();
  // buffer.writeln('\tString get languageTag {');
  // buffer.writeln('\t\tswitch (this) {');
  // for (I18nData locale in allLocales) {
  //   buffer.writeln(
  //       '\t\t\tcase $enumName.${locale.locale.enumConstant}: return \'${locale.locale.languageTag}\';');
  // }
  // buffer.writeln('\t\t}');
  // buffer.writeln('\t}');

  // buffer.writeln();
  // buffer.writeln('\tLocale get flutterLocale {');
  // buffer.writeln('\t\tswitch (this) {');
  // for (I18nData locale in allLocales) {
  //   buffer.write(
  //       '\t\t\tcase $enumName.${locale.locale.enumConstant}: return const Locale.fromSubtags(');
  //   if (locale.locale.language != null)
  //     buffer.write('languageCode: \'${locale.locale.language}\'');
  //   if (locale.locale.script != null) {
  //     if (locale.locale.language != null) buffer.write(', ');
  //     buffer.write('scriptCode: \'${locale.locale.script}\', ');
  //   }
  //   if (locale.locale.country != null) {
  //     if (locale.locale.language != null || locale.locale.script != null)
  //       buffer.write(', ');
  //     buffer.write('countryCode: \'${locale.locale.country}\'');
  //   }
  //   buffer.writeln(');');
  // }
  // buffer.writeln('\t\t}');
  // buffer.writeln('\t}');
  buffer.writeln('}');

  // string extension
  buffer.writeln();
  buffer.writeln('extension String${enumName}Extensions on String {');
  buffer.writeln('\t$enumName? to$enumName() {');
  buffer.writeln('\t\tswitch (this) {');
  for (I18nData locale in allLocales) {
    buffer.writeln(
        '\t\t\tcase \'${locale.locale.languageTag}\': return $enumName.${locale.locale.enumConstant};');
  }
  buffer.writeln('\t\t\tdefault: return null;');
  buffer.writeln('\t\t}');
  buffer.writeln('\t}');
  buffer.writeln('}');
}

void _generateTranslationWrapper({
  required StringBuffer buffer,
  required I18nConfig config,
  required String baseClassName,
  required String translationProviderKey,
  required String currLocaleVar,
}) {
//   const String translationProviderClass = 'TranslationProvider';
//   const String translationProviderStateClass = '_TranslationProviderState';
  const String inheritedClass = 'InheritedLocaleData';
//   final String enumName = config.enumName;
//
//   // TranslationProvider
//   buffer.writeln();
//   buffer.writeln('// wrappers');
//   buffer.writeln();
//   buffer.writeln(
//       'GlobalKey<$translationProviderStateClass> $translationProviderKey = GlobalKey<$translationProviderStateClass>();');
//   buffer.writeln();
//   buffer.writeln('class $translationProviderClass extends StatefulWidget {');
//   buffer.writeln(
//       '\t$translationProviderClass({required this.child}) : super(key: $translationProviderKey);');
//   buffer.writeln();
//   buffer.writeln('\tfinal Widget child;');
//   buffer.writeln();
//   buffer.writeln('\t@override');
//   buffer.writeln(
//       '\t$translationProviderStateClass createState() => $translationProviderStateClass();');
//
//   buffer.writeln();
//   buffer.writeln('\tstatic $inheritedClass of(BuildContext context) {');
//   buffer.writeln(
//       '\t\tfinal inheritedWidget = context.dependOnInheritedWidgetOfExactType<_InheritedLocaleData>();');
//   buffer.writeln('\t\tif (inheritedWidget == null) {');
//   buffer.writeln(
//       '\t\t\tthrow \'Please wrap your app with "TranslationProvider".\';');
//   buffer.writeln('\t\t}');
//   buffer.writeln('\t\treturn inheritedWidget;');
//   buffer.writeln('\t}');
//
//   buffer.writeln('}');
//
//   buffer.writeln();
//   buffer.writeln(
//       'class $translationProviderStateClass extends State<$translationProviderClass> {');
//   buffer.writeln('\t$enumName locale = $currLocaleVar;');
//   buffer.writeln();
//   buffer.writeln('\tvoid setLocale($enumName newLocale) {');
//   buffer.writeln('\t\tsetState(() {');
//   buffer.writeln('\t\t\tlocale = newLocale;');
//   buffer.writeln('\t\t});');
//   buffer.writeln('\t}');
//   buffer.writeln();
//   buffer.writeln('\t@override');
//   buffer.writeln('\tWidget build(BuildContext context) {');
//   buffer.writeln('\t\treturn $inheritedClass(');
//   buffer.writeln('\t\t\tlocale: locale,');
//   buffer.writeln('\t\t\tchild: widget.child,');
//   buffer.writeln('\t\t);');
//   buffer.writeln('\t}');
//   buffer.writeln('}');
//

  // InheritedLocaleData
  if (!config.dartOnly) {
    buffer.writeln();
    buffer.writeln('extension Ext$inheritedClass on $inheritedClass {');
    buffer.writeln(
        '\t$baseClassName get translations => localeId.locale.translations;');
    buffer.writeln('}');
  }
//   buffer.writeln();
//   buffer.writeln('class $inheritedClass extends InheritedWidget {');
//   buffer.writeln('\tfinal $enumName locale;');
//   buffer.writeln(
//       '\tLocale get flutterLocale => locale.flutterLocale; // shortcut');
//   buffer.writeln(
//       '\tfinal $baseClassName translations; // store translations to avoid switch call');
//   buffer.writeln();
//   buffer.writeln(
//       '\t$inheritedClass({required this.locale, required Widget child})');
//   buffer.writeln(
//       '\t\t: translations = locale.translations, super(child: child);');
//   buffer.writeln();
//   buffer.writeln('\t@override');
//   buffer.writeln('\tbool updateShouldNotify($inheritedClass oldWidget) {');
//   buffer.writeln('\t\treturn oldWidget.locale != locale;');
//   buffer.writeln('\t}');
//   buffer.writeln('}');
}

void _generatePluralResolvers({
  required StringBuffer buffer,
  required I18nConfig config,
  required String pluralResolverType,
  required String pluralResolverCardinal,
  required String pluralResolverOrdinal,
}) {
  buffer.writeln();

  if (!config.hasPlurals()) {
    buffer.writeln('// pluralization feature not used');
    return;
  }

  buffer.writeln('// pluralization resolvers');

  buffer.writeln();
  buffer.writeln(
      'typedef $pluralResolverType = String Function(num n, {String? zero, String? one, String? two, String? few, String? many, String? other});');

  if (config.unsupportedPluralLanguages.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('PluralResolver _missingPluralResolver(String language) {');
    buffer
        .writeln('\tthrow \'Resolver for <lang = \$language> not specified\';');
    buffer.writeln('}');
  }

  buffer.writeln();
  buffer.writeln('// prepared by fast_i18n');

  // cardinal resolvers
  for (final entry in config.renderedCardinalResolvers.entries) {
    buffer.writeln();
    _generatePluralFunction(
        buffer: buffer,
        config: config,
        ruleSet: entry.value,
        functionName: '_pluralCardinal${entry.key.capitalize()}');
  }

  // ordinal resolvers
  for (final entry in config.renderedOrdinalResolvers.entries) {
    buffer.writeln();
    _generatePluralFunction(
        buffer: buffer,
        config: config,
        ruleSet: entry.value,
        functionName: '_pluralOrdinal${entry.key.capitalize()}');
  }
}

/// Generates the plural resolver for one language and type (cardial, ordinal).
void _generatePluralFunction({
  required StringBuffer buffer,
  required I18nConfig config,
  required RuleSet ruleSet,
  required String functionName,
}) {
  buffer.write('String $functionName(num n, {');
  for (int i = 0; i < Quantity.values.length; i++) {
    if (i != 0) buffer.write(', ');
    buffer.write('String? ${Quantity.values[i].paramName()}');
  }
  buffer.writeln('}) {');

  if (ruleSet.i || ruleSet.v) {
    buffer.writeln('\tfinal i = n.toInt();');
  }

  if (ruleSet.v) {
    buffer.writeln(
        '\tfinal v = i == n ? 0 : n.toString().split(\'.\')[1].length;');
  }

  bool first = true;
  for (final rule in ruleSet.rules) {
    if (first) {
      buffer.write('\tif ');
    } else {
      buffer.write('\t} else if ');
    }
    buffer.writeln('(${rule.condition}) {');
    buffer.writeln(
        '\t\treturn ${rule.result.paramName()} ?? ${ruleSet.defaultQuantity.paramName()}!;');
    first = false;
  }

  if (!first) {
    buffer.writeln('\t}');
  }

  buffer.writeln('\treturn ${ruleSet.defaultQuantity.paramName()}!;');
  buffer.writeln('}');
}

// void _generateHelpers(
//     {required StringBuffer buffer, required I18nConfig config}) {
//   final enumName = config.enumName;
//   buffer.writeln();
//   buffer.writeln('// helpers');
//   buffer.writeln();
//   buffer.writeln(
//       'final _localeRegex = RegExp(r\'^${RegexUtils.LOCALE_REGEX_RAW}\$\');');
//   buffer.writeln('$enumName? _selectLocale(String localeRaw) {');
//   buffer.writeln('\tfinal match = _localeRegex.firstMatch(localeRaw);');
//   buffer.writeln('\t$enumName? selected;');
//   buffer.writeln('\tif (match != null) {');
//   buffer.writeln('\t\tfinal language = match.group(1);');
//   buffer.writeln('\t\tfinal country = match.group(5);');
//   buffer.writeln();
//
//   // match exactly
//   buffer.writeln('\t\t// match exactly');
//   buffer.writeln('\t\tselected = $enumName.values');
//   buffer.writeln('\t\t\t.cast<$enumName?>()');
//   buffer.writeln(
//       '\t\t\t.firstWhere((supported) => supported?.languageTag == localeRaw.replaceAll(\'_\', \'-\'), orElse: () => null);');
//   buffer.writeln();
//
//   // match language
//   buffer.writeln('\t\tif (selected == null && language != null) {');
//   buffer.writeln('\t\t\t// match language');
//   buffer.writeln('\t\t\tselected = $enumName.values');
//   buffer.writeln('\t\t\t\t.cast<$enumName?>()');
//   buffer.writeln(
//       '\t\t\t\t.firstWhere((supported) => supported?.languageTag.startsWith(language) == true, orElse: () => null);');
//   buffer.writeln('\t\t}');
//   buffer.writeln();
//
//   // match country
//   buffer.writeln('\t\tif (selected == null && country != null) {');
//   buffer.writeln('\t\t\t// match country');
//   buffer.writeln('\t\t\tselected = $enumName.values');
//   buffer.writeln('\t\t\t\t.cast<$enumName?>()');
//   buffer.writeln(
//       '\t\t\t\t.firstWhere((supported) => supported?.languageTag.contains(country) == true, orElse: () => null);');
//   buffer.writeln('\t\t}');
//
//   buffer.writeln('\t}');
//   buffer.writeln('\treturn selected;');
//   buffer.writeln('}');
// }

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
  } else if (node is PluralNode) {
    return node.quantities.entries.length;
  } else if (node is ContextNode) {
    return node.entries.entries.length;
  } else {
    return 0;
  }
}
