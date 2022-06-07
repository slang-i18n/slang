import 'package:slang/builder/generator/helper.dart';
import 'package:slang/builder/model/build_config.dart';
import 'package:slang/builder/model/i18n_config.dart';
import 'package:slang/builder/model/i18n_data.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/utils/path_utils.dart';

String generateHeader(
  I18nConfig config,
  List<I18nData> allLocales,
) {
  const String baseLocaleVar = '_baseLocale';
  final String baseClassName = getClassNameRoot(
    baseName: config.baseName,
    visibility: config.translationClassVisibility,
    locale: config.baseLocale,
  );
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
    baseClassName: baseClassName,
  );

  if (config.localeHandling) {
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
    baseClassName: baseClassName,
  );

  _generateContextEnums(buffer: buffer, config: config);

  _generateInterfaces(buffer: buffer, config: config);

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
      '// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, library_private_types_in_public_api');
}

void _generateImports(I18nConfig config, StringBuffer buffer) {
  buffer.writeln();
  final imports = [
    ...config.imports,
    if (config.flutterIntegration) ...[
      'package:flutter/widgets.dart',
      'package:slang_flutter/slang_flutter.dart',
    ] else
      'package:slang/slang.dart'
  ]..sort((a, b) => a.compareTo(b));

  for (final i in imports) {
    buffer.writeln('import \'$i\';');
  }

  // add export statements
  if (config.flutterIntegration) {
    buffer.writeln('export \'package:slang_flutter/slang_flutter.dart\';');
  } else {
    buffer.writeln('export \'package:slang/slang.dart\';');
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
  required String baseClassName,
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

  buffer.writeln('enum $enumName with BaseAppLocale<$baseClassName> {');
  for (int i = 0; i < allLocales.length; i++) {
    final I18nLocale locale = allLocales[i].locale;
    final String className = getClassNameRoot(
      baseName: config.baseName,
      visibility: config.translationClassVisibility,
      locale: locale,
    );

    buffer
        .write('\t${locale.enumConstant}(languageCode: \'${locale.language}\'');
    if (locale.script != null) {
      buffer.write(', scriptCode: \'${locale.script}\'');
    }
    if (locale.country != null) {
      buffer.write(', countryCode: \'${locale.country}\'');
    }
    buffer.write(', build: $className.build)');
    if (i != allLocales.length - 1) {
      buffer.writeln(',');
    } else {
      buffer.writeln(';');
    }
  }

  buffer.writeln();
  buffer.writeln(
      '\tconst $enumName({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element');

  buffer.writeln();
  buffer.writeln('\t@override final String languageCode;');
  buffer.writeln('\t@override final String? scriptCode;');
  buffer.writeln('\t@override final String? countryCode;');
  buffer.writeln('\t@override final TranslationBuilder<$baseClassName> build;');
  if (config.localeHandling) {
    buffer.writeln();
    buffer.writeln('\t/// Gets current instance managed by [LocaleSettings].');
    buffer.writeln(
        '\t$baseClassName get translations => LocaleSettings.instance.translationMap[this]!;');
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
  final String enumName = config.enumName;

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
  if (config.flutterIntegration) {
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
        '\tstatic $baseClassName of(BuildContext context) => InheritedLocaleData.of<$enumName, $baseClassName>(context).translations;');
    buffer.writeln('}');

    // provider
    buffer.writeln();
    buffer.writeln('/// The provider for method B');
    buffer.writeln(
        'class TranslationProvider extends BaseTranslationProvider<$enumName, $baseClassName> {');
    buffer.writeln('\tTranslationProvider({required super.child}) : super(');
    buffer.writeln('\t\tinitLocale: LocaleSettings.instance.currentLocale,');
    buffer.writeln(
        '\t\tinitTranslations: LocaleSettings.instance.currentTranslations,');
    buffer.writeln('\t);');
    buffer.writeln();
    buffer.writeln(
        '\tstatic InheritedLocaleData<$enumName, $baseClassName> of(BuildContext context) => InheritedLocaleData.of<$enumName, $baseClassName>(context);');
    buffer.writeln('}');

    // BuildContext extension for provider
    buffer.writeln();
    buffer.writeln('/// Method C: BuildContext extension');
    buffer.writeln('///');
    buffer.writeln('/// For a shorter alternative to `TranslationProvider.of(context)`, a BuildContext extension is provided:');
    buffer.writeln('///');
    buffer.writeln('/// Usage (e.g. in a widget\'s `build` method:');
    buffer.writeln('/// context.tr.someKey.anotherKey');
    buffer.writeln('extension BuildContextTranslationsExtension on BuildContext {');
    buffer.writeln('  $baseClassName get tr => TranslationProvider.of(this).translations;');
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
  final String baseClass = config.flutterIntegration
      ? 'BaseFlutterLocaleSettings'
      : 'BaseLocaleSettings';

  buffer.writeln();
  buffer
      .writeln('/// Manages all translation instances and the current locale');
  buffer.writeln(
      'class $settingsClass extends $baseClass<$enumName, $baseClassName> {');
  buffer.writeln('\t$settingsClass._() : super(');
  buffer.writeln('\t\tlocales: $enumName.values,');
  buffer.writeln('\t\tbaseLocale: _baseLocale,');
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
  buffer.writeln(
      '\tstatic $enumName setLocaleRaw(String rawLocale) => instance.setLocaleRaw(rawLocale);');
  if (config.flutterIntegration) {
    buffer.writeln(
        '\tstatic $enumName useDeviceLocale() => instance.useDeviceLocale();');
    buffer.writeln(
        '\tstatic List<Locale> get supportedLocales => instance.supportedLocales;');
  }
  buffer.writeln(
      '\tstatic List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;');
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
  required String baseClassName,
}) {
  const String utilClass = 'AppLocaleUtils';
  final String enumName = config.enumName;

  buffer.writeln();
  buffer.writeln('/// Provides utility functions without any side effects.');
  buffer.writeln(
      'class $utilClass extends BaseAppLocaleUtils<$enumName, $baseClassName> {');
  buffer.writeln(
      '\t$utilClass._() : super(baseLocale: $baseLocaleVar, locales: $enumName.values);');
  buffer.writeln();
  buffer.writeln('\tstatic final instance = $utilClass._();');

  buffer.writeln();
  buffer
      .writeln('\t// static aliases (checkout base methods for documentation)');
  buffer.writeln(
      '\tstatic $enumName parse(String rawLocale) => instance.parse(rawLocale);');
  if (config.flutterIntegration) {
    buffer.writeln(
        '\tstatic $enumName findDeviceLocale() => instance.findDeviceLocale();');
  }

  buffer.writeln('}');
}

void _generateContextEnums({
  required StringBuffer buffer,
  required I18nConfig config,
}) {
  final contexts = config.contexts.where((c) => c.generateEnum);

  if (contexts.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('// context enums');
  }

  for (final contextType in contexts) {
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
  if (config.interface.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('// interfaces generated as mixins');
  }

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
