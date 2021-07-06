import 'dart:collection';

import 'package:fast_i18n/src/generator/helper.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:fast_i18n/src/model/pluralization.dart';
import 'package:fast_i18n/src/string_extensions.dart';

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

  final pluralizationResolver = config.renderedPluralizationResolvers
      .cast<PluralizationResolver?>()
      .firstWhere((r) => r?.language == localeData.locale.language,
          orElse: () => null);

  // only for the first class
  bool root = true;

  do {
    ClassTask task = queue.removeFirst();

    _generateClass(
        config,
        localeData.base,
        localeData.locale.language,
        localeData.localeTag,
        pluralizationResolver,
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
  String language,
  String locale,
  PluralizationResolver? pluralizationResolver,
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
    final baseClassName = getClassName(
        parentName: className, locale: config.baseLocale.toLanguageTag());
    final fallbackStrategy = config.fallbackStrategy == FallbackStrategy.strict
        ? 'implements'
        : 'extends';
    buffer.writeln('class $finalClassName $fallbackStrategy $baseClassName {');
  }

  if (config.fallbackStrategy == FallbackStrategy.strict || base)
    buffer.writeln('\t$finalClassName._(); // no constructor');
  else
    buffer.writeln('\t$finalClassName._() : super._(); // no constructor');

  buffer.writeln();
  buffer.writeln('\tstatic $finalClassName _instance = $finalClassName._();');
  if (config.translationClassVisibility == TranslationClassVisibility.public)
    buffer.writeln('\tstatic $finalClassName get instance => _instance;');
  buffer.writeln();

  currMembers.forEach((key, value) {
    key = key.toCase(config.keyCase);

    buffer.write('\t');
    if (!base) buffer.write('@override ');

    if (value is TextNode) {
      if (value.params.isEmpty) {
        buffer.writeln('String get $key => \'${value.content}\';');
      } else {
        buffer.writeln(
            'String $key${_toParameterList(value.params, config)} => \'${value.content}\';');
      }
    } else if (value is ListNode) {
      String type = value.plainStrings ? 'String' : 'dynamic';
      buffer.write('List<$type> get $key => ');
      _generateList(config, base, language, locale, pluralizationResolver,
          buffer, queue, className, value.entries, 0);
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
          _generateMap(config, base, language, locale, pluralizationResolver,
              buffer, queue, childClassNoLocale, value.entries, 0);
          break;
        case ObjectNodeType.pluralCardinal:
        case ObjectNodeType.pluralOrdinal:
          // pluralization
          buffer.write('String $key');
          _addPluralizationCall(
            buffer: buffer,
            config: config,
            resolver: pluralizationResolver,
            language: language,
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
    buffer.writeln('\tdynamic operator[](String key) {');
    buffer.writeln(
        '\t\treturn _translationMap[${config.enumName}.${locale.toEnumConstant()}]${nsExl(config)}[key];');
    buffer.writeln('\t}');
  }

  buffer.writeln('}');
}

/// generates a map of ONE locale
/// similar to _generateClass but anonymous and accessible via key
void _generateMap(
  I18nConfig config,
  bool base,
  String language,
  String locale,
  PluralizationResolver? pluralizationResolver,
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
            '\'$key\': ${_toParameterList(value.params, config)} => \'${value.content}\',');
      }
    } else if (value is ListNode) {
      buffer.write('\'$key\': ');
      _generateList(config, base, language, locale, pluralizationResolver,
          buffer, queue, className, value.entries, depth + 1);
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
          _generateMap(config, base, language, locale, pluralizationResolver,
              buffer, queue, childClassNoLocale, value.entries, depth + 1);
          break;
        case ObjectNodeType.pluralCardinal:
        case ObjectNodeType.pluralOrdinal:
          // pluralization
          buffer.write('\'$key\': ');
          _addPluralizationCall(
              buffer: buffer,
              config: config,
              resolver: pluralizationResolver,
              language: language,
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
  String language,
  String locale,
  PluralizationResolver? pluralizationResolver,
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
            '${_toParameterList(value.params, config)} => \'${value.content}\',');
      }
    } else if (value is ListNode) {
      _generateList(config, base, language, locale, pluralizationResolver,
          buffer, queue, className, value.entries, depth + 1);
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
          _generateMap(config, base, language, locale, pluralizationResolver,
              buffer, queue, childClassNoLocale, value.entries, depth + 1);
          break;
        case ObjectNodeType.pluralCardinal:
        case ObjectNodeType.pluralOrdinal:
          // pluralization
          _addPluralizationCall(
              buffer: buffer,
              config: config,
              resolver: pluralizationResolver,
              language: language,
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
      '${nsLate(config)}Map<${config.enumName}, Map<String, dynamic>> _translationMap = {');

  for (I18nData localeData in translations) {
    final pluralizationResolver = config.renderedPluralizationResolvers
        .cast<PluralizationResolver?>()
        .firstWhere((r) => r?.language == localeData.locale.language,
            orElse: () => null);

    buffer.writeln(
        '\t${config.enumName}.${localeData.locale.toLanguageTag().toEnumConstant()}: {');
    _generateTranslationMapRecursive(buffer, localeData.root, '', config,
        pluralizationResolver, localeData.locale.language);
    buffer.writeln('\t},');
  }

  buffer.writeln('};');
}

_generateTranslationMapRecursive(
    StringBuffer buffer,
    Node parent,
    String path,
    I18nConfig config,
    PluralizationResolver? pluralizationResolver,
    String language) {
  if (parent is ObjectNode) {
    parent.entries.forEach((key, value) {
      key = key.toCase(config.keyCase);
      if (path.isNotEmpty) key = '$path.$key';

      if (value is TextNode) {
        if (value.params.isEmpty) {
          buffer.writeln('\t\t\'$key\': \'${value.content}\',');
        } else {
          buffer.writeln(
              '\t\t\'$key\': ${_toParameterList(value.params, config)} => \'${value.content}\',');
        }
      } else if (value is ListNode) {
        // convert ListNode to ObjectNode with index as object keys
        final Map<String, Node> entries = {
          for (int i = 0; i < value.entries.length; i++)
            i.toString(): value.entries[i]
        };
        final converted = ObjectNode(entries, ObjectNodeType.classType, null);

        _generateTranslationMapRecursive(
            buffer, converted, key, config, pluralizationResolver, language);
      } else if (value is ObjectNode) {
        if (value.type == ObjectNodeType.pluralCardinal ||
            value.type == ObjectNodeType.pluralOrdinal) {
          buffer.write('\t\t\'$key\': ');
          _addPluralizationCall(
            buffer: buffer,
            config: config,
            resolver: pluralizationResolver,
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
              buffer, value, key, config, pluralizationResolver, language);
        }
      }
    });
  }
}

/// returns the parameter list
/// e.g. ({required Object name, required Object age})
String _toParameterList(List<String> params, I18nConfig config) {
  StringBuffer buffer = StringBuffer();
  buffer.write('({');
  for (int i = 0; i < params.length; i++) {
    if (i != 0) buffer.write(', ');
    buffer.write('${nsReq(config)}required Object ');
    buffer.write(params[i]);
  }
  buffer.write('})');
  return buffer.toString();
}

void _addPluralizationCall(
    {required StringBuffer buffer,
    required I18nConfig config,
    required PluralizationResolver? resolver,
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
  final params = paramSet.where((p) => p != 'count').toList();

  // parameters with count as first number
  buffer.write('({${nsReq(config)}required num count');
  for (int i = 0; i < params.length; i++) {
    buffer.write(', ${nsReq(config)}required Object ');
    buffer.write(params[i]);
  }

  // custom resolver has precedence
  buffer.write(
      '}) => (_pluralResolvers${cardinal ? 'Cardinal' : 'Ordinal'}[\'$language\'] ?? ');

  if (resolver != null) {
    // call predefined resolver
    if (cardinal)
      buffer.writeln('_pluralCardinal${language.capitalize()})(count,');
    else
      buffer.writeln('_pluralOrdinal${language.capitalize()})(count,');
  } else {
    // throw error
    buffer.writeln('_missingPluralResolver(\'$language\'))(count,');
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
  final params = paramSet.where((p) => p != 'context').toList();

  // parameters with count as first number
  buffer.write('({${nsReq(config)}required $contextEnumName context');
  for (int i = 0; i < params.length; i++) {
    buffer.write(', ${nsReq(config)}required Object ');
    buffer.write(params[i]);
  }
  buffer.writeln('}) {');

  _addTabs(buffer, depth + 2);
  buffer.writeln('switch (context) {');

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
  }
}

/// writes count times \t to the buffer
void _addTabs(StringBuffer buffer, int count) {
  for (int i = 0; i < count; i++) {
    buffer.write('\t');
  }
}
