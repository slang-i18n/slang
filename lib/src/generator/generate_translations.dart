import 'dart:collection';

import 'package:fast_i18n/src/generator/helper.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/i18n_locale.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:fast_i18n/src/utils/string_extensions.dart';

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
void generateTranslations(
    StringBuffer buffer, I18nConfig config, I18nData localeData) {
  Queue<ClassTask> queue = Queue<ClassTask>();

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
  final finalClassName = getClassName(parentName: className, locale: locale);

  buffer.writeln();

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
      String type = value.genericType != null ? value.genericType! : 'dynamic';
      buffer.write('List<$type>$optional get $key => ');
      _generateList(config, base, locale, hasPluralResolver, buffer, queue,
          className, value.entries, 0);
    } else if (value is ObjectNode) {
      String childClassNoLocale =
          getClassName(parentName: className, childName: key);

      switch (value.type) {
        case ObjectNodeType.classType:
          // generate a class later on
          queue.add(ClassTask(childClassNoLocale, value));
          String childClassWithLocale = getClassName(
              parentName: className, childName: key, locale: locale);
          buffer.writeln(
              '$childClassWithLocale$optional get $key => $childClassWithLocale._instance;');
          break;
        case ObjectNodeType.map:
          // inline map
          String type =
              value.genericType != null ? value.genericType! : 'dynamic';
          buffer.write('Map<String, $type>$optional get $key => ');
          _generateMap(config, base, locale, hasPluralResolver, buffer, queue,
              childClassNoLocale, value.entries, 0);
          break;
        case ObjectNodeType.pluralCardinal:
        case ObjectNodeType.pluralOrdinal:
          // pluralization
          buffer.write('String$optional $key');
          _addPluralizationCall(
            buffer: buffer,
            config: config,
            hasPluralResolver: hasPluralResolver,
            language: locale.language ?? I18nLocale.UNDEFINED_LANGUAGE,
            cardinal: value.type == ObjectNodeType.pluralCardinal,
            key: key,
            children: value.entries,
            depth: 0,
          );
          break;
        case ObjectNodeType.context:
          // custom context
          buffer.write('String$optional $key');
          _addContextCall(
            buffer: buffer,
            config: config,
            contextEnumName: value.contextHint!.enumName,
            children: value.entries,
            depth: 0,
          );
      }
    }
  });

  if (root && config.renderFlatMap) {
    // add map operator for translation map
    buffer.writeln();
    buffer.writeln('\t/// A flat map containing all translations.');
    if (!base) buffer.writeln('\t@override');
    buffer.writeln('\tdynamic operator[](String key) {');
    buffer.writeln(
        '\t\treturn _translationMap[${config.enumName}.${locale.enumConstant}]![key];');
    buffer.writeln('\t}');
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

      switch (value.type) {
        case ObjectNodeType.classType:
          // generate a class later on
          queue.add(ClassTask(childClassNoLocale, value));
          String childClassWithLocale = getClassName(
              parentName: className, childName: key, locale: locale);
          buffer.writeln('\'$key\': $childClassWithLocale._instance,');
          break;
        case ObjectNodeType.map:
          // inline map
          buffer.write('\'$key\': ');
          _generateMap(config, base, locale, hasPluralResolver, buffer, queue,
              childClassNoLocale, value.entries, depth + 1);
          break;
        case ObjectNodeType.pluralCardinal:
        case ObjectNodeType.pluralOrdinal:
          // pluralization
          buffer.write('\'$key\': ');
          _addPluralizationCall(
              buffer: buffer,
              config: config,
              hasPluralResolver: hasPluralResolver,
              language: locale.language ?? I18nLocale.UNDEFINED_LANGUAGE,
              cardinal: value.type == ObjectNodeType.pluralCardinal,
              key: key,
              children: value.entries,
              depth: depth + 1);
          break;
        case ObjectNodeType.context:
          // custom context
          buffer.write('\'$key\': ');
          _addContextCall(
            buffer: buffer,
            config: config,
            contextEnumName: value.contextHint!.enumName,
            children: value.entries,
            depth: depth + 1,
          );
      }
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
    Node value = currList[i];
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
      String key = depth.toString() + 'i' + i.toString();
      String childClassNoLocale =
          getClassName(parentName: className, childName: key);

      switch (value.type) {
        case ObjectNodeType.classType:
          // generate a class later on
          queue.add(ClassTask(childClassNoLocale, value));
          String childClassWithLocale = getClassName(
              parentName: className, childName: key, locale: locale);
          buffer.writeln('$childClassWithLocale._instance,');
          break;
        case ObjectNodeType.map:
          // inline map
          _generateMap(config, base, locale, hasPluralResolver, buffer, queue,
              childClassNoLocale, value.entries, depth + 1);
          break;
        case ObjectNodeType.pluralCardinal:
        case ObjectNodeType.pluralOrdinal:
          // pluralization
          _addPluralizationCall(
              buffer: buffer,
              config: config,
              hasPluralResolver: hasPluralResolver,
              language: locale.language ?? I18nLocale.UNDEFINED_LANGUAGE,
              cardinal: value.type == ObjectNodeType.pluralCardinal,
              key: key,
              children: value.entries,
              depth: depth + 1);
          break;
        case ObjectNodeType.context:
          // custom context
          _addContextCall(
            buffer: buffer,
            config: config,
            contextEnumName: value.contextHint!.enumName,
            children: value.entries,
            depth: depth + 1,
          );
      }
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

generateTranslationMap(
    StringBuffer buffer, I18nConfig config, List<I18nData> translations) {
  buffer.writeln();
  buffer.writeln('/// A flat map containing all translations.');
  buffer.writeln(
      '/// Only for edge cases! For simple maps, use the map function of this library.');
  buffer.writeln(
      'late Map<${config.enumName}, Map<String, dynamic>> _translationMap = {');

  for (I18nData localeData in translations) {
    final language =
        localeData.locale.language ?? I18nLocale.UNDEFINED_LANGUAGE;
    final hasPluralResolver = config.hasPluralResolver(language);

    buffer.writeln('\t${config.enumName}.${localeData.locale.enumConstant}: {');
    _generateTranslationMapRecursive(
      buffer: buffer,
      curr: localeData.root,
      config: config,
      hasPluralResolver: hasPluralResolver,
      language: language,
    );
    buffer.writeln('\t},');
  }

  buffer.writeln('};');
}

_generateTranslationMapRecursive({
  required StringBuffer buffer,
  required Node curr,
  required I18nConfig config,
  required bool hasPluralResolver,
  required String language,
}) {
  if (curr is TextNode) {
    if (curr.params.isEmpty) {
      buffer.writeln('\t\t\'${curr.path}\': \'${curr.content}\',');
    } else {
      buffer.writeln(
          '\t\t\'${curr.path}\': ${_toParameterList(curr.params, curr.paramTypeMap)} => \'${curr.content}\',');
    }
  } else if (curr is ListNode) {
    curr.entries.forEach((child) {
      _generateTranslationMapRecursive(
        buffer: buffer,
        curr: child,
        config: config,
        hasPluralResolver: hasPluralResolver,
        language: language,
      );
    });
  } else if (curr is ObjectNode) {
    if (curr.type == ObjectNodeType.pluralCardinal ||
        curr.type == ObjectNodeType.pluralOrdinal) {
      buffer.write('\t\t\'${curr.path}\': ');
      _addPluralizationCall(
        buffer: buffer,
        config: config,
        hasPluralResolver: hasPluralResolver,
        language: language,
        cardinal: curr.type == ObjectNodeType.pluralCardinal,
        key: curr.path,
        children: curr.entries,
        depth: 1,
      );
    } else if (curr.type == ObjectNodeType.context) {
      buffer.write('\t\t\'${curr.path}\': ');
      _addContextCall(
        buffer: buffer,
        config: config,
        contextEnumName: curr.contextHint!.enumName,
        children: curr.entries,
        depth: 1,
      );
    } else {
      // recursive
      curr.entries.values.forEach((child) {
        _generateTranslationMapRecursive(
          buffer: buffer,
          curr: child,
          config: config,
          hasPluralResolver: hasPluralResolver,
          language: language,
        );
      });
    }
  } else {
    throw 'This should not happen';
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
    required bool cardinal,
    required String key,
    required Map<String, Node> children,
    required int depth}) {
  final textNodeList = children.values.cast<TextNode>().toList();

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
      '}) => (_pluralResolvers${cardinal ? 'Cardinal' : 'Ordinal'}[\'$language\'] ?? ');

  if (hasPluralResolver) {
    // call predefined resolver
    if (cardinal)
      buffer.writeln(
          '_pluralCardinal${language.capitalize()})($PLURAL_PARAMETER,');
    else
      buffer.writeln(
          '_pluralOrdinal${language.capitalize()})($PLURAL_PARAMETER,');
  } else {
    // throw error
    buffer.writeln('_missingPluralResolver(\'$language\'))($PLURAL_PARAMETER,');
  }

  final keys = children.keys.toList();
  for (int i = 0; i < textNodeList.length; i++) {
    _addTabs(buffer, depth + 2);
    buffer.writeln('${keys[i]}: \'${textNodeList[i].content}\',');
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
