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
        localeData,
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
  I18nData localeData,
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

  final rootClassName = getClassNameRoot(
    baseName: config.baseName,
    visibility: config.translationClassVisibility,
    locale: localeData.locale,
  );
  final finalClassName = getClassName(
    parentName: className,
    locale: localeData.locale,
  );

  final mixinStr =
      node.interface != null ? ' with ${node.interface!.name}' : '';

  if (localeData.base) {
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

  // constructor and custom fields
  final callSuperConstructor = !localeData.base &&
      config.fallbackStrategy == FallbackStrategy.baseLocale;
  if (root) {
    buffer.writeln();
    buffer.writeln(
        '\t/// You can call this constructor and build your own translation instance of this locale.');
    buffer.writeln(
        '\t/// Constructing via the enum [${config.enumName}.build] is preferred.');

    if (!config.hasPlurals() && !callSuperConstructor) {
      buffer.writeln('\t$finalClassName.build();');
    } else {
      if (config.hasPlurals()) {
        buffer.writeln(
            '\t$finalClassName.build({PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})');
      } else {
        buffer.writeln('\t$finalClassName.build()');
      }

      buffer.write('\t\t: ');

      if (config.hasPlurals()) {
        buffer.writeln('_cardinalResolver = cardinalResolver,');
        buffer.write('\t\t  _ordinalResolver = ordinalResolver');
      }
      if (callSuperConstructor) {
        if (config.hasPlurals()) {
          buffer.writeln(',');
          buffer.write('\t\t  ');
        }
        buffer.write('super.build()');
      }
      buffer.writeln(';');
    }

    if (config.renderFlatMap) {
      // flat map
      buffer.writeln();
      buffer.writeln('\t/// Access flat map');
      buffer.write('\t');
      if (!localeData.base) {
        buffer.write('@override ');
      }

      buffer.write('dynamic operator[](String key) => _flatMap[key]');

      if (config.fallbackStrategy == FallbackStrategy.baseLocale &&
          !localeData.base) {
        buffer.writeln(' ?? super._flatMap[key];');
      } else {
        buffer.writeln(';');
      }

      buffer.writeln();
      buffer.writeln('\t// Internal flat map initialized lazily');
      buffer.write('\t');
      if (!localeData.base) buffer.write('@override ');
      buffer.writeln(
          'late final Map<String, dynamic> _flatMap = _buildFlatMap();');
    }

    if (config.hasPlurals()) {
      buffer.writeln();
      buffer.write('\t');
      if (!localeData.base) buffer.write('@override ');
      buffer.writeln(
          'final PluralResolver? _cardinalResolver; // ignore: unused_field');
      buffer.write('\t');
      if (!localeData.base) buffer.write('@override ');
      buffer.writeln(
          'final PluralResolver? _ordinalResolver; // ignore: unused_field');
    }
  } else {
    if (callSuperConstructor) {
      buffer.writeln(
          '\t$finalClassName._($rootClassName root) : this._root = root, super._(root);');
    } else {
      buffer.writeln('\t$finalClassName._(this._root);');
    }
  }

  // root
  buffer.writeln();
  if (!localeData.base) {
    buffer.write('\t@override ');
  } else {
    buffer.write('\t');
  }

  if (root) {
    buffer.write('late final $rootClassName _root = this;');
  } else {
    buffer.write('final $rootClassName _root;');
  }
  buffer.writeln(' // ignore: unused_field');

  buffer.writeln();
  buffer.writeln('\t// Translations');

  bool prevHasComment = false;
  node.entries.forEach((key, value) {
    // comment handling
    if (value.comment != null) {
      // add comment add on the line above
      buffer.writeln();
      buffer.writeln('\t/// ${value.comment}');
      prevHasComment = true;
    } else {
      if (prevHasComment) {
        // add a new line to separate from previous entry with comment
        buffer.writeln();
      }
      prevHasComment = false;
    }

    buffer.write('\t');
    if (!localeData.base ||
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
      _generateList(config, localeData.base, localeData.locale,
          hasPluralResolver, buffer, queue, className, value.entries, 0);
    } else if (value is ObjectNode) {
      String childClassNoLocale =
          getClassName(parentName: className, childName: key);

      if (value.isMap) {
        // inline map
        buffer.write('Map<String, ${value.genericType}>$optional get $key => ');
        _generateMap(
            config,
            localeData.base,
            localeData.locale,
            hasPluralResolver,
            buffer,
            queue,
            childClassNoLocale,
            value.entries,
            0);
      } else {
        // generate a class later on
        queue.add(ClassTask(childClassNoLocale, value));
        String childClassWithLocale = getClassName(
            parentName: className, childName: key, locale: localeData.locale);
        buffer.writeln(
            'late final $childClassWithLocale$optional $key = $childClassWithLocale._(_root);');
      }
    } else if (value is PluralNode) {
      buffer.write('String$optional $key');
      _addPluralizationCall(
        buffer: buffer,
        config: config,
        hasPluralResolver: hasPluralResolver,
        language: localeData.locale.language ?? I18nLocale.UNDEFINED_LANGUAGE,
        node: value,
        depth: 0,
      );
    } else if (value is ContextNode) {
      buffer.write('String$optional $key');
      _addContextCall(
        buffer: buffer,
        config: config,
        node: value,
        depth: 0,
      );
    }
  });

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
        buffer.writeln('\'$key\': $childClassWithLocale._(_root),');
      }
    } else if (value is PluralNode) {
      buffer.write('\'$key\': ');
      _addPluralizationCall(
        buffer: buffer,
        config: config,
        hasPluralResolver: hasPluralResolver,
        language: locale.language ?? I18nLocale.UNDEFINED_LANGUAGE,
        node: value,
        depth: depth + 1,
      );
    } else if (value is ContextNode) {
      buffer.write('\'$key\': ');
      _addContextCall(
        buffer: buffer,
        config: config,
        node: value,
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
      final String key = depth.toString() + 'i' + i.toString();
      final String childClassNoLocale =
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
        buffer.writeln('$childClassWithLocale._(_root),');
      }
    } else if (value is PluralNode) {
      _addPluralizationCall(
        buffer: buffer,
        config: config,
        hasPluralResolver: hasPluralResolver,
        language: locale.language ?? I18nLocale.UNDEFINED_LANGUAGE,
        node: value,
        depth: depth + 1,
      );
    } else if (value is ContextNode) {
      _addContextCall(
        buffer: buffer,
        config: config,
        node: value,
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

void _addPluralizationCall({
  required StringBuffer buffer,
  required I18nConfig config,
  required bool hasPluralResolver,
  required String language,
  required PluralNode node,
  required int depth,
}) {
  final textNodeList = node.quantities.values.toList();

  if (textNodeList.isEmpty) {
    throw ('${node.path} is empty but it is marked for pluralization.');
  }

  // parameters are union sets over all plural forms
  final paramSet = <String>{};
  for (final textNode in textNodeList) {
    paramSet.addAll(textNode.params);
  }
  final params = paramSet.where((p) => p != node.paramName).toList();

  // parameters with count as first number
  buffer.write('({required num ${node.paramName}');
  for (int i = 0; i < params.length; i++) {
    buffer.write(', required Object ');
    buffer.write(params[i]);
  }

  // custom resolver has precedence
  buffer.write(
      '}) => (${node.pluralType == PluralType.cardinal ? '_root._cardinalResolver' : '_root._ordinalResolver'} ?? ');

  if (hasPluralResolver) {
    // call predefined resolver
    if (node.pluralType == PluralType.cardinal) {
      buffer.writeln(
          '_pluralCardinal${language.capitalize()})(${node.paramName},');
    } else {
      buffer.writeln(
          '_pluralOrdinal${language.capitalize()})(${node.paramName},');
    }
  } else {
    // throw error
    buffer.writeln('_missingPluralResolver(\'$language\'))(${node.paramName},');
  }

  for (final quantity in node.quantities.entries) {
    _addTabs(buffer, depth + 2);
    buffer
        .writeln('${quantity.key.paramName()}: \'${quantity.value.content}\',');
  }

  _addTabs(buffer, depth + 1);
  buffer.write(')');

  if (depth == 0) {
    buffer.writeln(';');
  } else {
    buffer.writeln(',');
  }
}

void _addContextCall({
  required StringBuffer buffer,
  required I18nConfig config,
  required ContextNode node,
  required int depth,
}) {
  final textNodeList = node.entries.values.toList();

  // parameters are union sets over all plural forms
  final paramSet = <String>{};
  for (final textNode in textNodeList) {
    paramSet.addAll(textNode.params);
  }
  final params = paramSet.where((p) => p != node.paramName).toList();

  // parameters with context as first parameter
  buffer.write('({required ${node.context.enumName} ${node.paramName}');
  for (int i = 0; i < params.length; i++) {
    buffer.write(', required Object ');
    buffer.write(params[i]);
  }
  buffer.writeln('}) {');

  _addTabs(buffer, depth + 2);
  buffer.writeln('switch (${node.paramName}) {');

  for (final entry in node.entries.entries) {
    _addTabs(buffer, depth + 3);
    buffer.writeln(
        'case ${node.context.enumName}.${entry.key}: return \'${entry.value.content}\';');
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
