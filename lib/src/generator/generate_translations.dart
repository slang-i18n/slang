import 'dart:collection';

import 'package:fast_i18n/src/generator/helper.dart';
import 'package:fast_i18n/src/model/i18n_config.dart';
import 'package:fast_i18n/src/model/i18n_data.dart';
import 'package:fast_i18n/src/model/node.dart';
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
void generateLocale(
    StringBuffer buffer, I18nConfig config, I18nData localeData) {
  Queue<ClassTask> queue = Queue<ClassTask>();

  queue.add(ClassTask(
    getClassNameRoot(
        baseName: config.baseName,
        visibility: config.translationClassVisibility),
    localeData.root.entries,
  ));

  do {
    ClassTask task = queue.removeFirst();

    _generateClass(
      config,
      localeData.base,
      localeData.localeTag,
      buffer,
      queue,
      task.className,
      task.members,
    );
  } while (queue.isNotEmpty);
}

/// generates a class and all of its members of ONE locale
/// adds subclasses to the queue
void _generateClass(
  I18nConfig config,
  bool base,
  String locale,
  StringBuffer buffer,
  Queue<ClassTask> queue,
  String className,
  Map<String, Node> currMembers,
) {
  final finalClassName = getClassName(parentName: className, locale: locale);

  buffer.writeln();

  if (base) {
    buffer.writeln('class $finalClassName {');
  } else {
    final baseClassName =
        getClassName(parentName: className, locale: config.baseLocale);
    buffer.writeln('class $finalClassName implements $baseClassName {');
  }

  buffer.writeln('\t$finalClassName._(); // no constructor');
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
            'String $key${_toParameterList(value.params)} => \'${value.content}\';');
      }
    } else if (value is ListNode) {
      String type = value.plainStrings ? 'String' : 'dynamic';
      buffer.write('List<$type> get $key => ');
      _generateList(base, locale, buffer, queue, className, value.entries, 0);
    } else if (value is ObjectNode) {
      String childClassNoLocale =
          getClassName(parentName: className, childName: key);
      if (value.mapMode) {
        // inline map
        String type = value.plainStrings ? 'String' : 'dynamic';
        buffer.write('Map<String, $type> get $key => ');
        _generateMap(
            base, locale, buffer, queue, childClassNoLocale, value.entries, 0);
      } else {
        // generate a class later on
        queue.add(ClassTask(childClassNoLocale, value.entries));
        String childClassWithLocale =
            getClassName(parentName: className, childName: key, locale: locale);
        buffer.writeln(
            '$childClassWithLocale get $key => $childClassWithLocale._instance;');
      }
    }
  });

  buffer.writeln('}');
}

/// generates a map of ONE locale
/// similar to _generateClass but anonymous and accessible via key
void _generateMap(
  bool base,
  String locale,
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
            '\'$key\': ${_toParameterList(value.params)} => \'${value.content}\',');
      }
    } else if (value is ListNode) {
      buffer.write('\'$key\': ');
      _generateList(
          base, locale, buffer, queue, className, value.entries, depth + 1);
    } else if (value is ObjectNode) {
      String childClassNoLocale =
          getClassName(parentName: className, childName: key);
      if (value.mapMode) {
        // inline map
        buffer.write('\'$key\': ');
        _generateMap(base, locale, buffer, queue, childClassNoLocale,
            value.entries, depth + 1);
      } else {
        // generate a class later on
        queue.add(ClassTask(childClassNoLocale, value.entries));
        String childClassWithLocale =
            getClassName(parentName: className, childName: key, locale: locale);
        buffer.writeln('\'$key\': $childClassWithLocale._instance,');
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
  bool base,
  String locale,
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
            '${_toParameterList(value.params)} => \'${value.content}\',');
      }
    } else if (value is ListNode) {
      _generateList(
          base, locale, buffer, queue, className, value.entries, depth + 1);
    } else if (value is ObjectNode) {
      String child = depth.toString() + 'i' + i.toString();
      String childClassNoLocale =
          getClassName(parentName: className, childName: child);
      queue.add(ClassTask(childClassNoLocale, value.entries));

      String childClassWithLocale =
          getClassName(parentName: className, childName: child, locale: locale);
      buffer.writeln('$childClassWithLocale._instance,');
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
/// e.g. ({required Object name, required Object age}) for definition = true
/// or (name, age) for definition = false
String _toParameterList(List<String> params, {bool definition = true}) {
  StringBuffer buffer = StringBuffer();
  buffer.write('(');
  if (definition) buffer.write('{');
  for (int i = 0; i < params.length; i++) {
    if (i != 0) buffer.write(', ');
    if (definition) buffer.write('required Object ');
    buffer.write(params[i]);
  }
  if (definition) buffer.write('}');
  buffer.write(')');
  return buffer.toString();
}

/// writes count times \t to the buffer
void _addTabs(StringBuffer buffer, int count) {
  for (int i = 0; i < count; i++) {
    buffer.write('\t');
  }
}
