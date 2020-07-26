import 'dart:collection';

import 'package:fast_i18n/src/model.dart';

class Task {
  final String className;
  final Map<String, Value> map;

  Task(this.className, this.map);
}

String generate(I18nData data, List<String> locales) {
  StringBuffer buffer = StringBuffer();
  buffer.writeln('\n// Generated file. Do not edit.');
  buffer.writeln('\nimport \'package:flutter/foundation.dart\';');

  if (data.base)
    _generateMain(buffer, data.baseName, locales);
  else
    buffer.writeln('import \'${data.baseName}.g.dart\';');

  Queue<Task> queue = Queue();
  queue.add(Task(data.baseName.capitalize(), data.entries));
  bool root = true;
  do {
    Task task = queue.removeFirst();
    _generateClass(
        data.base, data.locale, buffer, queue, task.className, task.map, root);
    root = false;
  } while (queue.isNotEmpty);

  return buffer.toString();
}

void _generateMain(StringBuffer buffer, String baseName, List<String> locales) {
  // add imports to other locales
  locales.forEach((locale) {
    if (locale.isNotEmpty)
      buffer.writeln('import \'${baseName}_$locale.g.dart\';');
  });
  // import FastI18n
  buffer.writeln('import \'package:fast_i18n/fast_i18n.dart\';');

  const String mapVar = '_strings';
  const String localeVar = '_locale';
  const String settingsClass = 'LocaleSettings';
  const String defaultLocale = '';
  bool defaultingToEn = false;
  String className = baseName.capitalize();

  // current locale variable
  buffer.writeln('\nString $localeVar = \'$defaultLocale\';');

  // map
  buffer.writeln('Map<String, $className> $mapVar = {');
  locales.forEach((locale) {
    buffer.writeln('\t\'$locale\': $className${locale.capitalize()}.instance,');
  });
  if (locales.indexOf('en') == -1) {
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

void _generateClass(bool base, String locale, StringBuffer buffer,
    Queue<Task> queue, String className, Map<String, dynamic> map, bool root) {
  String finalClassName = className + locale.capitalize();

  if (base)
    buffer.writeln('\nclass $finalClassName {');
  else
    buffer.writeln('\nclass $finalClassName extends $className {');
  buffer.writeln('\tstatic $finalClassName _instance = $finalClassName();');
  buffer.writeln('\tstatic $finalClassName get instance => _instance;');
  buffer.writeln();

  map.forEach((key, value) {
    if (value is Text) {
      if (value.params.isEmpty) {
        buffer.writeln('\tString get $key => \'${value.content}\';');
      } else {
        buffer.writeln(
            '\tString $key${_toParameterList(value.params)} => \'${value.content}\';');
      }
    } else if (value is ChildNode) {
      String childClassName = className + key.capitalize();
      queue.add(Task(childClassName, value.entries));

      String finalChildClassName = childClassName + locale.capitalize();
      buffer.writeln(
          '\t$finalChildClassName get $key => $finalChildClassName._instance;');
    }
  });

  buffer.writeln('}');
}

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

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return '';
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
