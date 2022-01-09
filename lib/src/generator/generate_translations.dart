import 'dart:collection';

import 'package:fast_i18n/src/generator/helper.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:fast_i18n/src/model/pluralization.dart';
import 'package:fast_i18n/src/utils/string_extensions.dart';

part 'generate_translation_map.dart';

const PLURAL_PARAMETER = 'count';
const CONTEXT_PARAMETER = 'context';

/// decides which class should be generated
class ClassTask {
  final String className;
  final ObjectNode node;

  ClassTask(this.className, this.node);
}

/// generates all classes of one locale
/// all non-default locales has a postfix of their locale code
/// e.g. Strings, StringsDe, StringsFr
String generateTranslations(I18nConfig config, I18nData localeData) {
  final queue = Queue<ClassTask>();
  final buffer = StringBuffer();

  if (config.outputFormat == OutputFormat.multipleFiles) {
    // this is a part file
    buffer.writeln('part of \'${config.baseName}.g.dart\';');
  }

  queue.add(ClassTask(
    getClassNameRoot(
      baseName: config.baseName,
      visibility: config.translationClassVisibility,
    ),
    localeData.root,
  ));

  // only for the first class
  bool root = true;

  do {
    ClassTask task = queue.removeFirst();

    _generateClass(
        config,
        localeData.base,
        localeData.locale,
        config.hasPluralResolver(
            localeData.locale.language ?? I18nLocale.UNDEFINED_LANGUAGE),
        buffer,
        queue,
        task.className,
        task.node,
        root);

    root = false;
  } while (queue.isNotEmpty);

  return buffer.toString();
}

/// generates a class and all of its members of ONE locale
/// adds subclasses to the queue
void _generateClass(
  I18nConfig config,
  bool base,
  I18nLocale locale,
  bool hasPluralResolver,
  StringBuffer buffer,
  Queue<ClassTask> queue,
  String className,
  ObjectNode node,
  bool root,
) {
  buffer.writeln();

  if (root) {
    buffer.writeln('// Path: <root>');
  } else {
    buffer.writeln('// Path: ${node.path}');
  }

  final finalClassName = getClassName(parentName: className, locale: locale);

  final mixinStr =
      node.interface != null ? ' with ${node.interface!.name}' : '';

  if (base) {
    buffer.writeln('class $finalClassName$mixinStr {');
  } else {
    final baseClassName =
        getClassName(parentName: className, locale: config.baseLocale);

    if (config.fallbackStrategy == FallbackStrategy.none) {
      buffer.writeln(
          'class $finalClassName$mixinStr implements $baseClassName {');
    } else {
      buffer.writeln('class $finalClassName extends $baseClassName$mixinStr {');
    }
  }

  if (config.fallbackStrategy == FallbackStrategy.none || base)
    buffer.writeln('\t$finalClassName._(); // no constructor');
  else
    buffer.writeln('\t$finalClassName._() : super._(); // no constructor');

  buffer.writeln();
  buffer.writeln(
      '\tstatic final $finalClassName _instance = $finalClassName._();');
  if (config.translationClassVisibility == TranslationClassVisibility.public)
    buffer.writeln('\tstatic $finalClassName get instance => _instance;');
  buffer.writeln();

  node.entries.forEach((key, value) {
    buffer.write('\t');
    if (!base ||
        node.interface?.attributes
                .any((attribute) => attribute.attributeName == key) ==
            true) buffer.write('@override ');

    // even if this attribute exist, it has to satisfy the same signature as
    // specified in the interface
    // this error seems to occur when using in combination with "extends"
    final optional = config.fallbackStrategy == FallbackStrategy.baseLocale &&
            node.interface?.attributes.any((attribute) =>
                    attribute.optional && attribute.attributeName == key) ==
                true
        ? '?'
        : '';

    if (value is TextNode) {
      if (value.params.isEmpty) {
        buffer.writeln('String$optional get $key => \'${value.content}\';');
      } else {
        buffer.writeln(
            'String$optional $key${_toParameterList(value.params, value.paramTypeMap)} => \'${value.content}\';');
      }
    } else if (value is ListNode) {
      buffer.write('List<${value.genericType}>$optional get $key => ');
      _generateList(config, base, locale, hasPluralResolver, buffer, queue,
          className, value.entries, 0);
    } else if (value is ObjectNode) {
      String childClassNoLocale =
          getClassName(parentName: className, childName: key);

      if (value.isMap) {
        // inline map
        buffer.write('Map<String, ${value.genericType}>$optional get $key => ');
        _generateMap(config, base, locale, hasPluralResolver, buffer, queue,
            childClassNoLocale, value.entries, 0);
      } else {
        // generate a class later on
        queue.add(ClassTask(childClassNoLocale, value));
        String childClassWithLocale =
            getClassName(parentName: className, childName: key, locale: locale);
        buffer.writeln(
            '$childClassWithLocale$optional get $key => $childClassWithLocale._instance;');
      }
    } else if (value is PluralNode) {
      buffer.write('String$optional $key');
      _addPluralizationCall(
        buffer: buffer,
        config: config,
        hasPluralResolver: hasPluralResolver,
        language: locale.language ?? I18nLocale.UNDEFINED_LANGUAGE,
        pluralType: value.pluralType,
        key: key,
        children: value.quantities,
        depth: 0,
      );
    } else if (value is ContextNode) {
      buffer.write('String$optional $key');
      _addContextCall(
        buffer: buffer,
        config: config,
        contextEnumName: value.context.enumName,
        children: value.entries,
        depth: 0,
      );
    }
  });

  if (root && config.renderFlatMap) {
    // add map operator for translation map
    buffer.writeln();
    buffer.writeln('\t/// A flat map containing all translations.');
    buffer.write('\t');
    if (!base) buffer.write('@override ');
    buffer.writeln(
        'dynamic operator[](String key) => _translationMap${locale.languageTag.toCaseOfLocale(CaseStyle.pascal)}[key];');
  }

  buffer.writeln('}');
}

/// generates a map of ONE locale
/// similar to _generateClass but anonymous and accessible via key
void _generateMap(
  I18nConfig config,
  bool base,
  I18nLocale locale,
  bool hasPluralResolver,
  StringBuffer buffer,
  Queue<ClassTask> queue,
  String className, // without locale
  Map<String, Node> currMembers,
  int depth,
) {
  buffer.writeln('{');

  currMembers.forEach((key, value) {
    _addTabs(buffer, depth + 2);
    if (value is TextNode) {
      if (value.params.isEmpty) {
        buffer.writeln('\'$key\': \'${value.content}\',');
      } else {
        buffer.writeln(
            '\'$key\': ${_toParameterList(value.params, value.paramTypeMap)} => \'${value.content}\',');
      }
    } else if (value is ListNode) {
      buffer.write('\'$key\': ');
      _generateList(config, base, locale, hasPluralResolver, buffer, queue,
          className, value.entries, depth + 1);
    } else if (value is ObjectNode) {
      String childClassNoLocale =
          getClassName(parentName: className, childName: key);

      if (value.isMap) {
        // inline map
        buffer.write('\'$key\': ');
        _generateMap(config, base, locale, hasPluralResolver, buffer, queue,
            childClassNoLocale, value.entries, depth + 1);
      } else {
        // generate a class later on
        queue.add(ClassTask(childClassNoLocale, value));
        String childClassWithLocale =
            getClassName(parentName: className, childName: key, locale: locale);
        buffer.writeln('\'$key\': $childClassWithLocale._instance,');
      }
    } else if (value is PluralNode) {
      buffer.write('\'$key\': ');
      _addPluralizationCall(
          buffer: buffer,
          config: config,
          hasPluralResolver: hasPluralResolver,
          language: locale.language ?? I18nLocale.UNDEFINED_LANGUAGE,
          pluralType: value.pluralType,
          key: key,
          children: value.quantities,
          depth: depth + 1);
    } else if (value is ContextNode) {
      buffer.write('\'$key\': ');
      _addContextCall(
        buffer: buffer,
        config: config,
        contextEnumName: value.context.enumName,
        children: value.entries,
        depth: depth + 1,
      );
    }
  });

  _addTabs(buffer, depth + 1);

  buffer.write('}');

  if (depth == 0) {
    buffer.writeln(';');
  } else {
    buffer.writeln(',');
  }
}

/// generates a list
void _generateList(
  I18nConfig config,
  bool base,
  I18nLocale locale,
  bool hasPluralResolver,
  StringBuffer buffer,
  Queue<ClassTask> queue,
  String className,
  List<Node> currList,
  int depth,
) {
  buffer.writeln('[');

  for (int i = 0; i < currList.length; i++) {
    final Node value = currList[i];
    final String key = depth.toString() + 'i' + i.toString();

    _addTabs(buffer, depth + 2);
    if (value is TextNode) {
      if (value.params.isEmpty) {
        buffer.writeln('\'${value.content}\',');
      } else {
        buffer.writeln(
            '${_toParameterList(value.params, value.paramTypeMap)} => \'${value.content}\',');
      }
    } else if (value is ListNode) {
      _generateList(config, base, locale, hasPluralResolver, buffer, queue,
          className, value.entries, depth + 1);
    } else if (value is ObjectNode) {
      String childClassNoLocale =
          getClassName(parentName: className, childName: key);

      if (value.isMap) {
        // inline map
        _generateMap(config, base, locale, hasPluralResolver, buffer, queue,
            childClassNoLocale, value.entries, depth + 1);
      } else {
        // generate a class later on
        queue.add(ClassTask(childClassNoLocale, value));
        String childClassWithLocale =
            getClassName(parentName: className, childName: key, locale: locale);
        buffer.writeln('$childClassWithLocale._instance,');
      }
    } else if (value is PluralNode) {
      _addPluralizationCall(
          buffer: buffer,
          config: config,
          hasPluralResolver: hasPluralResolver,
          language: locale.language ?? I18nLocale.UNDEFINED_LANGUAGE,
          pluralType: value.pluralType,
          key: key,
          children: value.quantities,
          depth: depth + 1);
    } else if (value is ContextNode) {
      _addContextCall(
        buffer: buffer,
        config: config,
        contextEnumName: value.context.enumName,
        children: value.entries,
        depth: depth + 1,
      );
    }
  }

  _addTabs(buffer, depth + 1);

  buffer.write(']');

  if (depth == 0) {
    buffer.writeln(';');
  } else {
    buffer.writeln(',');
  }
}

/// returns the parameter list
/// e.g. ({required Object name, required Object age})
String _toParameterList(Set<String> params, Map<String, String> paramTypeMap) {
  StringBuffer buffer = StringBuffer();
  buffer.write('({');
  bool first = true;
  for (final param in params) {
    if (!first) buffer.write(', ');
    buffer.write('required ${paramTypeMap[param] ?? 'Object'} ');
    buffer.write(param);
    first = false;
  }
  buffer.write('})');
  return buffer.toString();
}

/// [key] is only used for debugging purposes
void _addPluralizationCall(
    {required StringBuffer buffer,
    required I18nConfig config,
    required bool hasPluralResolver,
    required String language,
    required PluralType pluralType,
    required String key,
    required Map<Quantity, TextNode> children,
    required int depth}) {
  final textNodeList = children.values.toList();

  if (textNodeList.isEmpty) {
    throw ('$key is empty but it is marked for pluralization.');
  }

  // parameters are union sets over all plural forms
  final paramSet = <String>{};
  for (final textNode in textNodeList) {
    paramSet.addAll(textNode.params);
  }
  final params = paramSet.where((p) => p != PLURAL_PARAMETER).toList();

  // parameters with count as first number
  buffer.write('({required num $PLURAL_PARAMETER');
  for (int i = 0; i < params.length; i++) {
    buffer.write(', required Object ');
    buffer.write(params[i]);
  }

  // custom resolver has precedence
  buffer.write(
      '}) => (_pluralResolvers${pluralType == PluralType.cardinal ? 'Cardinal' : 'Ordinal'}[\'$language\'] ?? ');

  if (hasPluralResolver) {
    // call predefined resolver
    if (pluralType == PluralType.cardinal) {
      buffer.writeln(
          '_pluralCardinal${language.capitalize()})($PLURAL_PARAMETER,');
    } else {
      buffer.writeln(
          '_pluralOrdinal${language.capitalize()})($PLURAL_PARAMETER,');
    }
  } else {
    // throw error
    buffer.writeln('_missingPluralResolver(\'$language\'))($PLURAL_PARAMETER,');
  }

  final keys = children.keys.toList();
  for (int i = 0; i < textNodeList.length; i++) {
    _addTabs(buffer, depth + 2);
    buffer.writeln('${keys[i].paramName()}: \'${textNodeList[i].content}\',');
  }

  _addTabs(buffer, depth + 1);
  buffer.write(')');

  if (depth == 0) {
    buffer.writeln(';');
  } else {
    buffer.writeln(',');
  }
}

void _addContextCall(
    {required StringBuffer buffer,
    required I18nConfig config,
    required String contextEnumName,
    required Map<String, Node> children,
    required int depth}) {
  final textNodeList = children.values.cast<TextNode>().toList();

  // parameters are union sets over all plural forms
  final paramSet = <String>{};
  for (final textNode in textNodeList) {
    paramSet.addAll(textNode.params);
  }
  final params = paramSet.where((p) => p != CONTEXT_PARAMETER).toList();

  // parameters with context as first parameter
  buffer.write('({required $contextEnumName $CONTEXT_PARAMETER');
  for (int i = 0; i < params.length; i++) {
    buffer.write(', required Object ');
    buffer.write(params[i]);
  }
  buffer.writeln('}) {');

  _addTabs(buffer, depth + 2);
  buffer.writeln('switch ($CONTEXT_PARAMETER) {');

  final keys = children.keys.toList();
  for (int i = 0; i < textNodeList.length; i++) {
    _addTabs(buffer, depth + 3);
    buffer.writeln(
        'case $contextEnumName.${keys[i]}: return \'${textNodeList[i].content}\';');
  }

  _addTabs(buffer, depth + 2);
  buffer.writeln('}');

  _addTabs(buffer, depth + 1);
  buffer.write('}');

  if (depth != 0) {
    buffer.writeln(',');
  } else {
    buffer.writeln();
  }
}

/// writes count times \t to the buffer
void _addTabs(StringBuffer buffer, int count) {
  for (int i = 0; i < count; i++) {
    buffer.write('\t');
  }
}
