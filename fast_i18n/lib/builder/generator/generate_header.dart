import 'package:fast_i18n/builder/generator/helper.dart';
import 'package:fast_i18n/builder/model/build_config.dart';
import 'package:fast_i18n/builder/model/i18n_config.dart';
import 'package:fast_i18n/builder/model/i18n_data.dart';
import 'package:fast_i18n/builder/model/node.dart';
import 'package:fast_i18n/builder/utils/path_utils.dart';

String generateHeader(
  I18nConfig config,
  List<I18nData> allLocales,
) {
  const String baseLocaleVar = '_baseLocale';
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

  _generateBaseLocale(
    buffer: buffer,
    config: config,
    baseLocaleVar: baseLocaleVar,
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
    );

    _generateLocaleSettings(
      buffer: buffer,
      config: config,
      allLocales: allLocales,
      baseClassName: baseClassName,
      pluralResolverType: pluralResolverType,
      pluralResolverCardinal: pluralResolverMapCardinal,
      pluralResolverOrdinal: pluralResolverMapOrdinal,
    );
  }

  _generateUtil(
    buffer: buffer,
    config: config,
    baseLocaleVar: baseLocaleVar,
  );

  _generateContextEnums(buffer: buffer, config: config);

  _generateInterfaces(buffer: buffer, config: config);

  _generateExtensions(
    buffer: buffer,
    config: config,
    allLocales: allLocales,
    baseClassName: baseClassName,
  );

  _generateMapper(
    buffer: buffer,
    config: config,
    allLocales: allLocales,
  );

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

  buffer.writeln();
  buffer.writeln(
      '// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables');
}

void _generateImports(I18nConfig config, StringBuffer buffer) {
  buffer.writeln();
  if (config.dartOnly) {
    buffer.writeln('import \'package:fast_i18n/fast_i18n.dart\';');
  } else {
    buffer.writeln(
        'import \'package:fast_i18n_flutter/fast_i18n_flutter.dart\';');
  }
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

void _generateBaseLocale({
  required StringBuffer buffer,
  required I18nConfig config,
  required String baseLocaleVar,
}) {
  final String enumName = config.enumName;

  buffer.writeln();
  buffer.writeln(
      'const $enumName $baseLocaleVar = $enumName.${config.baseLocale.enumConstant};');
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
    buffer.write('\t${locale.locale.enumConstant},');
    buffer.writeln(
        '\t// \'${locale.locale.languageTag}\'${locale.base ? ' (base locale, fallback)' : ''}');
  }
  buffer.writeln('}');
}

void _generateTranslationGetter({
  required StringBuffer buffer,
  required I18nConfig config,
  required String baseClassName,
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
      '$baseClassName get $translateVar => LocaleSettings.instance.currentTranslations;');

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
        '\tstatic $baseClassName of(BuildContext context) => InheritedLocaleData.of<$baseClassName>(context).translations;');
    buffer.writeln('}');

    // provider
    buffer.writeln();
    buffer.writeln('/// The provider for method B');
    buffer.writeln(
        'class TranslationProvider extends BaseTranslationProvider<$baseClassName> {');
    buffer.writeln('\tTranslationProvider({required Widget child}) : super(');
    buffer.writeln(
        '\t\tbaseLocaleId: LocaleSettings.instance.mapper.toId(_baseLocale),');
    buffer.writeln(
        '\t\tbaseTranslations: LocaleSettings.instance.currentTranslations,');
    buffer.writeln('\t\tchild: child,');
    buffer.writeln('\t);');
    buffer.writeln();
    buffer.writeln(
        '\tstatic InheritedLocaleData<$baseClassName> of(BuildContext context) => InheritedLocaleData.of<$baseClassName>(context);');
    buffer.writeln('}');
  }
}

void _generateLocaleSettings({
  required StringBuffer buffer,
  required I18nConfig config,
  required List<I18nData> allLocales,
  required String baseClassName,
  required String pluralResolverType,
  required String pluralResolverCardinal,
  required String pluralResolverOrdinal,
}) {
  const String settingsClass = 'LocaleSettings';
  final String enumName = config.enumName;
  final String baseClass =
      config.dartOnly ? 'BaseLocaleSettings' : 'BaseFlutterLocaleSettings';

  buffer.writeln();
  buffer
      .writeln('/// Manages all translation instances and the current locale');
  buffer.writeln(
      'class $settingsClass extends $baseClass<$enumName, $baseClassName> {');
  buffer.writeln('\t$settingsClass._() : super(');
  buffer.writeln('\t\tlocales: $enumName.values,');
  buffer.writeln('\t\tbaseLocale: _baseLocale,');
  buffer.writeln('\t\tmapper: _mapper,');
  buffer.writeln('\t\ttranslationMap: <$enumName, $baseClassName>{');
  for (I18nData locale in allLocales) {
    buffer.write('\t\t\t');
    buffer.write(config.enumName);
    buffer.write('.');
    buffer.write(locale.locale.enumConstant);
    buffer.write(': ');
    buffer.write(getClassNameRoot(
      baseName: config.baseName,
      locale: locale.locale,
      visibility: config.translationClassVisibility,
    ));
    buffer.writeln('.build(),');
  }
  buffer.writeln('\t\t},');
  buffer.writeln('\t\tutils: AppLocaleUtils.instance,');
  buffer.writeln('\t);');
  buffer.writeln();
  buffer.writeln('\tstatic final instance = $settingsClass._();');

  buffer.writeln();
  buffer
      .writeln('\t// static aliases (checkout base methods for documentation)');
  buffer.writeln(
      '\tstatic $enumName get currentLocale => instance.currentLocale;');
  buffer.writeln(
      '\tstatic $enumName setLocale($enumName locale) => instance.setLocale(locale);');
  if (!config.dartOnly) {
    buffer.writeln(
        '\tstatic $enumName setLocaleRaw(String rawLocale) => instance.setLocaleRaw(rawLocale);');
    buffer.writeln(
        '\tstatic $enumName useDeviceLocale() => instance.useDeviceLocale();');
    buffer.writeln(
        '\tstatic List<Locale> get supportedLocales => instance.supportedLocales;');
  }
  buffer.writeln(
      '\tstatic void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(');
  buffer.writeln('\t\tlanguage: language,');
  buffer.writeln('\t\tlocale: locale,');
  buffer.writeln('\t\tcardinalResolver: cardinalResolver,');
  buffer.writeln('\t\tordinalResolver: ordinalResolver,');
  buffer.writeln('\t);');

  buffer.writeln('}');
}

void _generateUtil({
  required StringBuffer buffer,
  required I18nConfig config,
  required String baseLocaleVar,
}) {
  const String utilClass = 'AppLocaleUtils';
  final String enumName = config.enumName;

  buffer.writeln();
  buffer.writeln('/// Provides utility functions without any side effects.');
  buffer.writeln('class $utilClass extends BaseAppLocaleUtils<$enumName> {');
  buffer.writeln(
      '\t$utilClass._() : super(mapper: _mapper, baseLocale: $baseLocaleVar);');
  buffer.writeln();
  buffer.writeln('\tstatic final instance = $utilClass._();');

  buffer.writeln();
  buffer
      .writeln('\t// static aliases (checkout base methods for documentation)');
  buffer.writeln(
      '\tstatic $enumName parse(String rawLocale) => instance.parse(rawLocale);');
  if (!config.dartOnly) {
    buffer.writeln(
        '\tstatic $enumName findDeviceLocale() => instance.findDeviceLocale();');
  }

  buffer.writeln('}');
}

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
    buffer.writeln('\t\treturn LocaleSettings.instance.translationMap[this]!;');
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
  buffer.writeln(
      '\t$baseClassName build({PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) {');

  buffer.writeln('\t\tswitch (this) {');
  for (I18nData locale in allLocales) {
    final className = getClassNameRoot(
      baseName: config.baseName,
      locale: locale.locale,
      visibility: config.translationClassVisibility,
    );
    buffer.writeln(
        '\t\t\tcase $enumName.${locale.locale.enumConstant}: return $className.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);');
  }
  buffer.writeln('\t\t}');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\tString get languageTag {');
  buffer.writeln('\t\tswitch (this) {');
  for (I18nData locale in allLocales) {
    buffer.writeln(
        '\t\t\tcase $enumName.${locale.locale.enumConstant}: return \'${locale.locale.languageTag}\';');
  }
  buffer.writeln('\t\t}');
  buffer.writeln('\t}');

  if (!config.dartOnly) {
    buffer.writeln();
    buffer.writeln('\tLocale get flutterLocale {');
    buffer.writeln('\t\tswitch (this) {');
    for (I18nData locale in allLocales) {
      buffer.write(
          '\t\t\tcase $enumName.${locale.locale.enumConstant}: return const Locale.fromSubtags(');
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
    buffer.writeln('\t\t}');
    buffer.writeln('\t}');
  }
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

void _generateMapper({
  required StringBuffer buffer,
  required I18nConfig config,
  required List<I18nData> allLocales,
}) {
  buffer.writeln();
  buffer.writeln('final _mapper = AppLocaleIdMapper<${config.enumName}>(');
  buffer.writeln('\tlocaleMap: {');
  for (I18nData locale in allLocales) {
    buffer.write('\t\tconst AppLocaleId(');
    buffer.write('languageCode: \'${locale.locale.language}\'');
    if (locale.locale.script != null) {
      buffer.write(', ');
      buffer.write('scriptCode: \'${locale.locale.script}\', ');
    }
    if (locale.locale.country != null) {
      buffer.write(', ');
      buffer.write('countryCode: \'${locale.locale.country}\'');
    }
    buffer.write('): ');
    buffer.write(config.enumName);
    buffer.write('.');
    buffer.write(locale.locale.enumConstant);
    buffer.writeln(',');
  }
  buffer.writeln('\t}');
  buffer.writeln(');');
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
