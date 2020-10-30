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
  buffer.writeln('import \'package:flutter/material.dart\';');
  buffer.writeln('import \'package:fast_i18n/fast_i18n.dart\';');

  _generateHeader(buffer, allLocales);

  buffer.writeln('\n// translations');

  allLocales.forEach((localeData) {
    _generateLocale(buffer, localeData);
  });

  return buffer.toString();
}

/// generates the header of the .g.dart file
/// contains the t function, LocaleSettings class and some global variables
void _generateHeader(StringBuffer buffer, List<I18nData> allLocales) {
  // identifiers
  const String mapVar = '_strings';
  const String baseLocaleVar = '_baseLocale';
  const String localeVar = '_locale';
  const String translationsClass = 'Translations';
  const String settingsClass = 'LocaleSettings';
  const String translationProviderKey = '_translationProviderKey';
  const String translationProviderClass = 'TranslationProvider';
  const String translationProviderStateClass = '_TranslationProviderState';
  const String inheritedClass = '_InheritedLocaleData';

  // constants
  final String baseLocale = allLocales.first.globalConfig.baseLocale;
  final String baseClassName = allLocales.first.baseName.capitalize();
  bool defaultingToEn = false;

  // current locale variable
  buffer.writeln('\nconst String $baseLocaleVar = \'$baseLocale\';');
  buffer.writeln('String $localeVar = $baseLocaleVar;');

  // map
  buffer.writeln('Map<String, $baseClassName> $mapVar = {');
  allLocales.forEach((localeData) {
    String finalClassName = localeData.base
        ? baseClassName
        : baseClassName + localeData.locale.capitalize().replaceAll('-', '');
    buffer.writeln('\t\'${localeData.locale}\': $finalClassName.instance,');
  });
  if (baseLocale == '' &&
      allLocales.indexWhere((locale) => locale.locale == 'en') == -1) {
    buffer.writeln(
        '\t\'en\': $baseClassName.instance, // assume default locale is en, add a specific \'en\' locale to remove this or add config.i18n.json');
    defaultingToEn = true;
  }
  buffer.writeln('};');

  // t getter
  buffer.writeln('\n/// Method A: Simple');
  buffer.writeln('///');
  buffer.writeln(
      '/// Widgets using this method will not be updated after widget creation when locale changes.');
  buffer.writeln(
      '/// Translation happens during initialization of the widget (method call of t)');
  buffer.writeln('///');
  buffer.writeln('/// Usage:');
  buffer.writeln('/// String translated = t.someKey.anotherKey;');
  buffer.writeln('$baseClassName get t {');
  buffer.writeln('\treturn $mapVar[$localeVar];');
  buffer.writeln('}');

  // t getter (advanced)
  buffer.writeln('\n/// Method B: Advanced');
  buffer.writeln('///');
  buffer.writeln('/// Reacts on locale changes.');
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
      '/// final t = $translationsClass.of(context); // get t variable');
  buffer.writeln(
      '/// String translated = t.someKey.anotherKey; // use t variable');
  buffer.writeln('class $translationsClass {');
  buffer.writeln('\t$translationsClass._(); // no constructor');
  buffer.writeln('\n\tstatic $baseClassName of(BuildContext context) {');
  buffer.writeln(
      '\t\treturn context.dependOnInheritedWidgetOfExactType<$inheritedClass>().translations;');
  buffer.writeln('\t}');
  buffer.writeln('}');

  // settings
  buffer.writeln('\nclass $settingsClass {');
  buffer.writeln('\t$settingsClass._(); // no constructor');

  buffer.writeln(
      '\n\t/// use the locale of the device, fallback to default locale');
  buffer.writeln('\tstatic Future<void> useDeviceLocale() async {');
  buffer.writeln(
      '\t\t$localeVar = await FastI18n.findDeviceLocale($mapVar.keys.toList(), $baseLocaleVar);');
  buffer.writeln('\n\t\tif ($translationProviderKey != null)');
  buffer.writeln(
      '\t\t\t$translationProviderKey.currentState.setLocale($localeVar);');
  buffer.writeln('\t}');

  buffer.writeln('\n\t/// set the locale, fallback to default locale');
  buffer.writeln('\tstatic void setLocale(String locale) {');
  buffer.writeln(
      '\t\t$localeVar = FastI18n.selectLocale(locale, $mapVar.keys.toList(), $baseLocaleVar);');
  buffer.writeln('\n\t\tif ($translationProviderKey != null)');
  buffer.writeln(
      '\t\t\t$translationProviderKey.currentState.setLocale($localeVar);');
  buffer.writeln('\t}');

  buffer.writeln('\n\t/// get the current locale');
  buffer.writeln('\tstatic String get currentLocale {');
  if (defaultingToEn)
    buffer.writeln('\t\tif ($localeVar == \'en\') return \'$baseLocale\';');
  buffer.writeln('\t\treturn $localeVar;');
  buffer.writeln('\t}');

  buffer.writeln('\n\t/// get the base locale');
  buffer.writeln('\tstatic String get baseLocale {');
  buffer.writeln('\t\treturn $baseLocaleVar;');
  buffer.writeln('\t}');

  buffer.writeln('\n\t/// get the supported locales');
  buffer.writeln('\tstatic List<String> get locales {');
  buffer.writeln('\t\treturn $mapVar.keys.toList();');
  buffer.writeln('\t}');

  buffer.writeln('}');

  // TranslationProvider
  buffer.writeln(
      '\nGlobalKey<$translationProviderStateClass> $translationProviderKey = new GlobalKey<$translationProviderStateClass>();');
  buffer.writeln('class $translationProviderClass extends StatefulWidget {');
  buffer.writeln('\n\tfinal Widget child;');
  buffer.writeln(
      '\t$translationProviderClass({@required this.child}) : super(key: $translationProviderKey);');
  buffer.writeln('\n\t@override');
  buffer.writeln(
      '\t$translationProviderStateClass createState() => $translationProviderStateClass();');
  buffer.writeln('}');

  // TranslationProviderState
  buffer.writeln(
      '\nclass $translationProviderStateClass extends State<$translationProviderClass> {');
  buffer.writeln('\tString locale;');
  buffer.writeln('\n\tvoid setLocale(String newLocale) {');
  buffer.writeln('\t\tsetState(() {');
  buffer.writeln('\t\t\tlocale = newLocale;');
  buffer.writeln('\t\t});');
  buffer.writeln('\t}');
  buffer.writeln('\n\t@override');
  buffer.writeln('\tWidget build(BuildContext context) {');
  buffer.writeln('\t\treturn $inheritedClass(');
  buffer.writeln('\t\t\ttranslations: $mapVar[locale],');
  buffer.writeln('\t\t\tchild: widget.child,');
  buffer.writeln('\t\t);');
  buffer.writeln('\t}');
  buffer.writeln('}');

  // InheritedLocaleData
  buffer.writeln('\nclass $inheritedClass extends InheritedWidget {');
  buffer.writeln('\tfinal Strings translations;');
  buffer.writeln(
      '\t$inheritedClass({this.translations, Widget child}) : super(child: child);');
  buffer.writeln('\n\t@override');
  buffer.writeln('\tbool updateShouldNotify($inheritedClass oldWidget) {');
  buffer.writeln('\t\treturn oldWidget.translations != translations;');
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
  String finalClassName =
      base ? className : className + locale.capitalize().replaceAll('-', '');

  if (base)
    buffer.writeln('\nclass $finalClassName {');
  else
    buffer.writeln('\nclass $finalClassName extends $className {');
  buffer.writeln('\tstatic $finalClassName _instance = $finalClassName();');
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
            'String $key${_toParameterList(value.params)} => \'${value.content}\';');
      }
    } else if (value is ListNode) {
      String type = value.plainStrings ? 'String' : 'dynamic';
      buffer.write('List<$type> get $key => ');
      _generateList(base, locale, buffer, queue, className, value.entries, 0);
    } else if (value is ObjectNode) {
      String childClassName = className + key.capitalize();
      if (value.mapMode) {
        // inline map
        String type = value.plainStrings ? 'String' : 'dynamic';
        buffer.write('Map<String, $type> get $key => ');
        _generateMap(
            base, locale, buffer, queue, childClassName, value.entries, 0);
      } else {
        // generate a class later on
        queue.add(ClassTask(childClassName, value.entries));
        String finalChildClassName = base
            ? childClassName
            : childClassName + locale.capitalize().replaceAll('-', '');
        buffer.writeln(
            '$finalChildClassName get $key => $finalChildClassName._instance;');
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
    String className,
    Map<String, Value> currMembers,
    int depth) {
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
      String childClassName = className + key.capitalize();
      if (value.mapMode) {
        // inline map
        buffer.write('\'$key\': ');
        _generateMap(base, locale, buffer, queue, childClassName, value.entries,
            depth + 1);
      } else {
        // generate a class later on
        queue.add(ClassTask(childClassName, value.entries));
        String finalChildClassName = base
            ? childClassName
            : childClassName + locale.capitalize().replaceAll('-', '');
        buffer.writeln('\'$key\': $finalChildClassName._instance,');
      }
    }
  });

  _addTabs(buffer, depth + 1);
  buffer.write('}');
  if (depth == 0)
    buffer.writeln(';');
  else
    buffer.writeln(',');
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
