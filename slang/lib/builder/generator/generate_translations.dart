import 'dart:collection';

import 'package:slang/builder/generator/helper.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/model/generate_config.dart';
import 'package:slang/builder/model/i18n_data.dart';
import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang/builder/model/pluralization.dart';

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
String generateTranslations(GenerateConfig config, I18nData localeData) {
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
        config, localeData, buffer, queue, task.className, task.node, root);

    root = false;
  } while (queue.isNotEmpty);

  return buffer.toString();
}

/// generates a class and all of its members of ONE locale
/// adds subclasses to the queue
void _generateClass(
  GenerateConfig config,
  I18nData localeData,
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

  final baseClassName = getClassName(
    parentName: className,
    locale: config.baseLocale,
  );
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
    if (root) {
      buffer.writeln(
          'class $finalClassName$mixinStr implements BaseTranslations<${config.enumName}, $rootClassName> {');
    } else {
      buffer.writeln('class $finalClassName$mixinStr {');
    }
  } else {
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
    if (config.translationOverrides) {
      buffer.writeln(
          '\t/// [AppLocaleUtils.buildWithOverrides] is recommended for overriding.');
    }

    buffer.writeln(
        '\t$finalClassName.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})');
    if (!config.translationOverrides) {
      buffer.write(
          '\t\t: assert(overrides == null, \'Set "translation_overrides: true" in order to enable this feature.\'),\n\t\t  ');
    } else {
      buffer.write('\t\t: ');
    }
    buffer.writeln('\$meta = TranslationMetadata(');
    buffer.writeln(
        '\t\t    locale: ${config.enumName}.${localeData.locale.enumConstant},');
    buffer.writeln('\t\t    overrides: overrides ?? {},');
    buffer.writeln('\t\t    cardinalResolver: cardinalResolver,');
    buffer.writeln('\t\t    ordinalResolver: ordinalResolver,');
    buffer.write('\t\t  )');

    if (callSuperConstructor) {
      buffer.write(
          ',\n\t\t  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver)');
    }

    if (config.renderFlatMap) {
      buffer.writeln(' {');
      buffer.writeln('\t\t\$meta.setFlatMapFunction(_flatMapFunction);');
      buffer.writeln('\t}');
    } else {
      buffer.writeln(';');
    }

    buffer.writeln();
    buffer.writeln(
        '\t/// Metadata for the translations of <${localeData.locale.languageTag}>.');
    buffer.writeln(
        '\t@override final TranslationMetadata<${config.enumName}, $baseClassName> \$meta;');

    if (config.renderFlatMap) {
      // flat map
      buffer.writeln();
      buffer.writeln('\t/// Access flat map');
      buffer.write('\t');
      if (!localeData.base) {
        buffer.write('@override ');
      }

      buffer.write(
          'dynamic operator[](String key) => \$meta.getTranslation(key)');

      if (config.fallbackStrategy == FallbackStrategy.baseLocale &&
          !localeData.base) {
        buffer.writeln(' ?? super.\$meta.getTranslation(key);');
      } else {
        buffer.writeln(';');
      }
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

    if (value is StringTextNode) {
      final translationOverrides = config.translationOverrides
          ? 'TranslationOverrides.string(_root.\$meta, \'${value.path}\', ${_toParameterMap(value.params)}) ?? '
          : '';
      if (value.params.isEmpty) {
        buffer.writeln(
            'String$optional get $key => $translationOverrides\'${value.content}\';');
      } else {
        buffer.writeln(
            'String$optional $key${_toParameterList(value.params, value.paramTypeMap)} => $translationOverrides\'${value.content}\';');
      }
    } else if (value is RichTextNode) {
      buffer.write('TextSpan$optional ');
      if (value.params.isEmpty) {
        buffer.write('get $key');
      } else {
        buffer.write(key);
      }
      _addRichTextCall(
        buffer: buffer,
        config: config,
        node: value,
        includeArrowIfNoParams: true,
        depth: 0,
      );
    } else if (value is ListNode) {
      buffer.write('List<${value.genericType}>$optional get $key => ');
      _generateList(
        config: config,
        base: localeData.base,
        locale: localeData.locale,
        buffer: buffer,
        queue: queue,
        className: className,
        node: value,
        depth: 0,
      );
    } else if (value is ObjectNode) {
      String childClassNoLocale =
          getClassName(parentName: className, childName: key);

      if (value.isMap) {
        // inline map
        buffer.write('Map<String, ${value.genericType}>$optional get $key => ');
        _generateMap(
          config: config,
          base: localeData.base,
          locale: localeData.locale,
          buffer: buffer,
          queue: queue,
          className: childClassNoLocale,
          node: value,
          depth: 0,
        );
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
        language: localeData.locale.language,
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
void _generateMap({
  required GenerateConfig config,
  required bool base,
  required I18nLocale locale,
  required StringBuffer buffer,
  required Queue<ClassTask> queue,
  required String className, // without locale
  required ObjectNode node,
  required int depth,
}) {
  if (config.translationOverrides && node.genericType == 'String') {
    buffer
        .write('TranslationOverrides.map(_root.\$meta, \'${node.path}\') ?? ');
  }
  buffer.writeln('{');

  node.entries.forEach((key, value) {
    _addTabs(buffer, depth + 2);
    if (value is StringTextNode) {
      if (value.params.isEmpty) {
        buffer.writeln('\'$key\': \'${value.content}\',');
      } else {
        buffer.writeln(
            '\'$key\': ${_toParameterList(value.params, value.paramTypeMap)} => \'${value.content}\',');
      }
    } else if (value is ListNode) {
      buffer.write('\'$key\': ');
      _generateList(
        config: config,
        base: base,
        locale: locale,
        buffer: buffer,
        queue: queue,
        className: className,
        node: value,
        depth: depth + 1,
      );
    } else if (value is ObjectNode) {
      String childClassNoLocale =
          getClassName(parentName: className, childName: key);

      if (value.isMap) {
        // inline map
        buffer.write('\'$key\': ');
        _generateMap(
          config: config,
          base: base,
          locale: locale,
          buffer: buffer,
          queue: queue,
          className: childClassNoLocale,
          node: value,
          depth: depth + 1,
        );
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
        language: locale.language,
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
void _generateList({
  required GenerateConfig config,
  required bool base,
  required I18nLocale locale,
  required StringBuffer buffer,
  required Queue<ClassTask> queue,
  required String className,
  required ListNode node,
  required int depth,
}) {
  if (config.translationOverrides && node.genericType == 'String') {
    buffer
        .write('TranslationOverrides.list(_root.\$meta, \'${node.path}\') ?? ');
  }

  buffer.writeln('[');

  for (int i = 0; i < node.entries.length; i++) {
    final Node value = node.entries[i];

    _addTabs(buffer, depth + 2);
    if (value is StringTextNode) {
      if (value.params.isEmpty) {
        buffer.writeln('\'${value.content}\',');
      } else {
        buffer.writeln(
            '${_toParameterList(value.params, value.paramTypeMap)} => \'${value.content}\',');
      }
    } else if (value is ListNode) {
      _generateList(
        config: config,
        base: base,
        locale: locale,
        buffer: buffer,
        queue: queue,
        className: className,
        node: value,
        depth: depth + 1,
      );
    } else if (value is ObjectNode) {
      final String key = depth.toString() + 'i' + i.toString();
      final String childClassNoLocale =
          getClassName(parentName: className, childName: key);

      if (value.isMap) {
        // inline map
        _generateMap(
          config: config,
          base: base,
          locale: locale,
          buffer: buffer,
          queue: queue,
          className: childClassNoLocale,
          node: value,
          depth: depth + 1,
        );
      } else {
        // generate a class later on
        queue.add(ClassTask(childClassNoLocale, value));
        String childClassWithLocale = getClassName(
          parentName: className,
          childName: key,
          locale: locale,
        );
        buffer.writeln('$childClassWithLocale._(_root),');
      }
    } else if (value is PluralNode) {
      _addPluralizationCall(
        buffer: buffer,
        config: config,
        language: locale.language,
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
  if (params.isEmpty) {
    return '()';
  }
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

/// returns a map containing all parameters
/// e.g. {'name': name, 'age': age}
String _toParameterMap(Set<String> params) {
  StringBuffer buffer = StringBuffer();
  buffer.write('{');
  bool first = true;
  for (final param in params) {
    if (!first) buffer.write(', ');
    buffer.write('\'');
    buffer.write(param);
    buffer.write('\': ');
    buffer.write(param);
    first = false;
  }
  buffer.write('}');
  return buffer.toString();
}

void _addPluralizationCall({
  required StringBuffer buffer,
  required GenerateConfig config,
  required String language,
  required PluralNode node,
  required int depth,
  bool forceSemicolon = false,
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
  final prefix = node.pluralType.name;
  final translationOverrides = config.translationOverrides
      ? 'TranslationOverrides.plural(_root.\$meta, \'${node.path}\', ${_toParameterMap({
              ...params,
              node.paramName,
            })}) ?? '
      : '';
  buffer.writeln(
      '}) => $translationOverrides(_root.\$meta.${prefix}Resolver ?? PluralResolvers.$prefix(\'$language\'))(${node.paramName},');

  for (final quantity in node.quantities.entries) {
    _addTabs(buffer, depth + 2);
    buffer
        .writeln('${quantity.key.paramName()}: \'${quantity.value.content}\',');
  }

  _addTabs(buffer, depth + 1);
  buffer.write(')');

  if (depth == 0 || forceSemicolon) {
    buffer.writeln(';');
  } else {
    buffer.writeln(',');
  }
}

void _addRichTextCall({
  required StringBuffer buffer,
  required GenerateConfig config,
  required RichTextNode node,
  required bool includeArrowIfNoParams,
  required int depth,
  bool forceSemicolon = false,
}) {
  if (node.params.isNotEmpty) {
    buffer.write(_toParameterList(node.params, node.paramTypeMap));
  }

  if (node.params.isNotEmpty || includeArrowIfNoParams) {
    buffer.write(' => ');
  }

  if (config.translationOverrides) {
    buffer.write(
        'TranslationOverridesFlutter.rich(_root.\$meta, \'${node.path}\', ${_toParameterMap(node.params)}) ?? ');
  }

  buffer.writeln('TextSpan(children: [');
  for (final span in node.spans) {
    _addTabs(buffer, depth + 2);
    buffer.write(span.code);
    buffer.writeln(',');
  }
  _addTabs(buffer, depth + 1);
  if (depth == 0 || forceSemicolon) {
    buffer.writeln(']);');
  } else {
    buffer.writeln(']),');
  }
}

void _addContextCall({
  required StringBuffer buffer,
  required GenerateConfig config,
  required ContextNode node,
  required int depth,
  bool forceSemicolon = false,
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

  if (config.translationOverrides) {
    _addTabs(buffer, depth + 2);
    buffer.writeln(
        'final override = TranslationOverrides.context(_root.\$meta, \'${node.path}\', ${_toParameterMap({
          ...params,
          node.paramName,
        })});');

    _addTabs(buffer, depth + 2);
    buffer.writeln('if (override != null) {');

    _addTabs(buffer, depth + 3);
    buffer.writeln('return override;');

    _addTabs(buffer, depth + 2);
    buffer.writeln('}');
  }

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

  if (forceSemicolon) {
    buffer.writeln(';');
  } else if (depth != 0) {
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
