import 'dart:collection';

import 'package:fast_i18n/src/model.dart';

/// decides which class should be generated
class ClassTask {
  final String className;
  final Map<String, Value> members;

  ClassTask(this.className, this.members);
}

/// main generate function
/// returns a string representing the content of the .g.dart file
String generate(List<I18nData> allLocales) {
  StringBuffer buffer = StringBuffer();
  buffer.writeln('\n// Generated file. Do not edit.\n');
  buffer.writeln('import \'package:flutter/foundation.dart\';');
  buffer.writeln('import \'package:fast_i18n/fast_i18n.dart\';');

  _generateHeader(buffer, allLocales);

  allLocales.forEach((localeData) {
    _generateLocale(buffer, localeData);
  });

  return buffer.toString();
}

/// generates the header of the .g.dart file
/// contains the t function, LocaleSettings class and some global variables
void _generateHeader(StringBuffer buffer, List<I18nData> allLocales) {
  const String mapVar = '_strings';
  const String localeVar = '_locale';
  const String settingsClass = 'LocaleSettings';
  const String defaultLocale = '';
  bool defaultingToEn = false;
  String className = allLocales.first.baseName.capitalize();

  // current locale variable
  buffer.writeln('\nString $localeVar = \'$defaultLocale\';');

  // map
  buffer.writeln('Map<String, $className> $mapVar = {');
  allLocales.forEach((localeData) {
    buffer.writeln(
        '\t\'${localeData.locale}\': $className${localeData.locale.capitalize()}.instance,');
  });
  if (allLocales.indexWhere((locale) => locale.locale == 'en') == -1) {
    buffer.writeln(
        '\t\'en\': $className.instance, // assume default locale is en, add a specific \'en\' locale to remove this');
    defaultingToEn = true;
  }
  buffer.writeln('};');

  // t getter
  buffer.writeln(
      '\n// use this to get your translations, e.g. t.someKey.anotherKey');
  buffer.writeln('$className get t {');
  buffer.writeln('\treturn $mapVar[$localeVar];');
  buffer.writeln('}');

  // settings
  buffer.writeln('\nclass $settingsClass {');

  buffer.writeln(
      '\n\t// use this to use the locale of the device, fallback to default locale');
  buffer.writeln('\tstatic Future<void> useDeviceLocale() async {');
  buffer.writeln(
      '\t\t$localeVar = await FastI18n.findDeviceLocale($mapVar.keys.toList());');
  buffer.writeln('\t}');

  buffer.writeln('\n\t// use this to change your locale');
  buffer.writeln('\tstatic void setLocale(String locale) {');
  buffer.writeln('\t\t$localeVar = locale;');
  buffer.writeln('\t}');

  buffer.writeln(
      '\n\t// use this to get the current locale, an empty string is the default locale!');
  buffer.writeln('\tstatic String get currentLocale {');
  if (defaultingToEn)
    buffer.writeln('\t\tif ($localeVar == \'en\') return \'\';');
  buffer.writeln('\t\treturn $localeVar;');
  buffer.writeln('\t}');
  buffer.writeln('}');
}

/// generates all classes of one locale
/// all non-default locales has a postfix of their locale code
/// e.g. Strings, StringsDe, StringsFr
void _generateLocale(StringBuffer buffer, I18nData localeData) {
  Queue<ClassTask> queue = Queue();
  queue.add(
      ClassTask(localeData.baseName.capitalize(), localeData.root.entries));
  do {
    ClassTask task = queue.removeFirst();
    _generateClass(localeData.base, localeData.locale, buffer, queue,
        task.className, task.members);
  } while (queue.isNotEmpty);
}

/// generates a class and all of its members of ONE locale
/// adds subclasses to the queue
void _generateClass(bool base, String locale, StringBuffer buffer,
    Queue<ClassTask> queue, String className, Map<String, Value> currMembers) {
  String finalClassName = className + locale.capitalize();

  if (base)
    buffer.writeln('\nclass $finalClassName {');
  else
    buffer.writeln('\nclass $finalClassName extends $className {');
  buffer.writeln('\tstatic $finalClassName _instance = $finalClassName();');
  buffer.writeln('\tstatic $finalClassName get instance => _instance;');
  buffer.writeln();

  currMembers.forEach((key, value) {
    buffer.write('\t');
    if (value is TextNode) {
      if (value.params.isEmpty) {
        buffer.writeln('String get $key => \'${value.content}\';');
      } else {
        buffer.writeln(
            'String $key${_toParameterList(value.params)} => \'${value.content}\';');
      }
    } else if (value is ListNode) {
      buffer.write('List<dynamic> get $key => ');
      _generateList(base, locale, buffer, queue, className, value.entries, 0);
    } else if (value is ObjectNode) {
      String childClassName = className + key.capitalize();
      queue.add(ClassTask(childClassName, value.entries));

      String finalChildClassName = childClassName + locale.capitalize();
      buffer.writeln(
          '$finalChildClassName get $key => $finalChildClassName._instance;');
    }
  });

  buffer.writeln('}');
}

/// generates a list
void _generateList(bool base, String locale, StringBuffer buffer,
    Queue<ClassTask> queue, String className, List<Value> currList, int depth) {
  buffer.writeln('[');

  for (int i = 0; i < currList.length; i++) {
    Value value = currList[i];
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
      String childClassName = className + depth.toString() + 'i' + i.toString();
      queue.add(ClassTask(childClassName, value.entries));

      String finalChildClassName = childClassName + locale.capitalize();
      buffer.writeln('$finalChildClassName._instance,');
    }
  }

  _addTabs(buffer, depth + 1);
  buffer.write(']');
  if (depth == 0)
    buffer.writeln(';');
  else
    buffer.writeln(',');
}

/// returns the parameter list
/// e.g. ({@required Object name, @required Object age}) for definition = true
/// or (name, age) for definition = false
String _toParameterList(List<String> params, {bool definition = true}) {
  StringBuffer buffer = StringBuffer();
  buffer.write('(');
  if (definition) buffer.write('{');
  for (int i = 0; i < params.length; i++) {
    if (i != 0) buffer.write(', ');
    if (definition) buffer.write('@required Object ');
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

extension on String {
  /// capitalizes a given string
  /// 'hello' => 'Hello'
  /// 'heLLo' => 'HeLLo'
  /// 'Hello' => 'Hello'
  /// '' => ''
  String capitalize() {
    if (this.isEmpty) return '';
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
