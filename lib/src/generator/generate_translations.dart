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
  final Map<String, Node> members;

  ClassTask(this.className, this.members);
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
        visibility: config.translationClassVisibility),
    localeData.root.entries,
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
        task.members,
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
  Map<String, Node> currMembers,
  bool root,
) {
  final finalClassName = getClassName(parentName: className, locale: locale);

  buffer.writeln();

  if (base) {
    buffer.writeln('class $finalClassName {');
  } else {
    final baseClassName =
        getClassName(parentName: className, locale: config.baseLocale);
    final fallbackStrategy = config.fallbackStrategy == FallbackStrategy.none
        ? 'implements'
        : 'extends';
    buffer.writeln('class $finalClassName $fallbackStrategy $baseClassName {');
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

  currMembers.forEach((key, value) {
    buffer.write('\t');
    if (!base) buffer.write('@override ');

    if (value is TextNode) {
      if (value.params.isEmpty) {
        buffer.writeln('String get $key => \'${value.content}\';');
      } else {
        buffer.writeln(
            'String $key${_toParameterList(value.params, value.paramTypeMap, config)} => \'${value.content}\';');
      }
    } else if (value is ListNode) {
      String type = value.plainStrings ? 'String' : 'dynamic';
      buffer.write('List<$type> get $key => ');
      _generateList(config, base, locale, hasPluralResolver, buffer, queue,
          className, value.entries, 0);
    } else if (value is ObjectNode) {
      String childClassNoLocale =
          getClassName(parentName: className, childName: key);

      switch (value.type) {
        case ObjectNodeType.classType:
          // generate a class later on
          queue.add(ClassTask(childClassNoLocale, value.entries));
          String childClassWithLocale = getClassName(
              parentName: className, childName: key, locale: locale);
          buffer.writeln(
              '$childClassWithLocale get $key => $childClassWithLocale._instance;');
          break;
        case ObjectNodeType.map:
          // inline map
          String type = value.plainStrings ? 'String' : 'dynamic';
          buffer.write('Map<String, $type> get $key => ');
          _generateMap(config, base, locale, hasPluralResolver, buffer, queue,
              childClassNoLocale, value.entries, 0);
          break;
        case ObjectNodeType.pluralCardinal:
        case ObjectNodeType.pluralOrdinal:
          // pluralization
          buffer.write('String $key');
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
          buffer.write('String $key');
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
            '\'$key\': ${_toParameterList(value.params, value.paramTypeMap, config)} => \'${value.content}\',');
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
          queue.add(ClassTask(childClassNoLocale, value.entries));
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
            '${_toParameterList(value.params, value.paramTypeMap, config)} => \'${value.content}\',');
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
          queue.add(ClassTask(childClassNoLocale, value.entries));
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
      buffer,
      localeData.root,
      '',
      config,
      hasPluralResolver,
      language,
    );
    buffer.writeln('\t},');
  }

  buffer.writeln('};');
}

_generateTranslationMapRecursive(
  StringBuffer buffer,
  Node parent,
  String path,
  I18nConfig config,
  bool hasPluralResolver,
  String language,
) {
  if (parent is ObjectNode) {
    parent.entries.forEach((key, value) {
      if (path.isNotEmpty) key = '$path.$key';

      if (value is TextNode) {
        if (value.params.isEmpty) {
          buffer.writeln('\t\t\'$key\': \'${value.content}\',');
        } else {
          buffer.writeln(
              '\t\t\'$key\': ${_toParameterList(value.params, value.paramTypeMap, config)} => \'${value.content}\',');
        }
      } else if (value is ListNode) {
        // convert ListNode to ObjectNode with index as object keys
        final Map<String, Node> entries = {
          for (int i = 0; i < value.entries.length; i++)
            i.toString(): value.entries[i]
        };
        final converted = ObjectNode(
          parent: value,
          entries: entries,
          type: ObjectNodeType.classType,
          contextHint: null,
        );

        _generateTranslationMapRecursive(
            buffer, converted, key, config, hasPluralResolver, language);
      } else if (value is ObjectNode) {
        if (value.type == ObjectNodeType.pluralCardinal ||
            value.type == ObjectNodeType.pluralOrdinal) {
          buffer.write('\t\t\'$key\': ');
          _addPluralizationCall(
            buffer: buffer,
            config: config,
            hasPluralResolver: hasPluralResolver,
            language: language,
            cardinal: value.type == ObjectNodeType.pluralCardinal,
            key: key,
            children: value.entries,
            depth: 1,
          );
        } else if (value.type == ObjectNodeType.context) {
          buffer.write('\t\t\'$key\': ');
          _addContextCall(
            buffer: buffer,
            config: config,
            contextEnumName: value.contextHint!.enumName,
            children: value.entries,
            depth: 1,
          );
        } else {
          // recursive
          _generateTranslationMapRecursive(
              buffer, value, key, config, hasPluralResolver, language);
        }
      }
    });
  }
}

/// returns the parameter list
/// e.g. ({required Object name, required Object age})
String _toParameterList(
    Set<String> params, Map<String, String> paramTypeMap, I18nConfig config) {
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
