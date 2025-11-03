import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:slang/src/builder/generator/helper.dart';
import 'package:slang/src/builder/model/autodoc_config.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/generate_config.dart';
import 'package:slang/src/builder/model/i18n_data.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/node.dart';
import 'package:slang/src/builder/model/pluralization.dart';
import 'package:slang/src/builder/utils/encryption_utils.dart';

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
String generateTranslations(GenerateConfig config, I18nData localeData,
    List<I18nData> allTranslations) {
  final queue = Queue<ClassTask>();
  final buffer = StringBuffer();

  buffer.writeln('''
///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
${!config.format.enabled ? '// dart format off' : ''}
''');

  if (localeData.base) {
    buffer.writeln("part of '${config.outputFileName}';");
  } else {
    final imports = [
      config.outputFileName,
      ...config.imports,
      'package:intl/intl.dart',
      'package:slang/generated.dart',
      if (config.obfuscation.enabled) 'package:slang/secret.dart',
      if (config.translationOverrides) 'package:slang/overrides.dart',
      if (config.flutterIntegration) 'package:flutter/widgets.dart',
    ]..sort((a, b) => a.compareTo(b));

    for (final i in imports) {
      buffer.writeln('import \'$i\';');
    }
  }

  queue.add(ClassTask(
    getClassNameRoot(
      className: config.className,
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
      buffer,
      queue,
      task.className,
      task.node,
      root,
      allTranslations,
    );

    root = false;
  } while (queue.isNotEmpty);

  if (config.renderFlatMap) {
    buffer.writeln();
    buffer.writeln(generateTranslationMap(config, localeData));
  }

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
  List<I18nData> allTranslations,
) {
  buffer.writeln();

  if (root) {
    buffer.writeln('// Path: <root>');
  } else {
    buffer.writeln('// Path: ${node.path}');
  }

  // The root class of **this** locale (path-independent).
  final rootClassName = localeData.base
      ? config.className
      : getClassNameRoot(
          className: config.className,
          locale: localeData.locale,
        );

  // The current class name.
  final finalClassName = switch (root) {
    true => switch (localeData.base) {
        true => config.className,
        false =>
          getClassNameRoot(className: className, locale: localeData.locale),
      },
    false => getClassName(
        base: localeData.base,
        visibility: config.translationClassVisibility,
        parentName: className,
        locale: localeData.locale,
      ),
  };

  final mixinStr =
      node.interface != null ? ' with ${node.interface!.name}' : '';

  if (localeData.base) {
    if (root) {
      // Add typedef for backwards compatibility
      final legacyClassName = getClassNameRoot(
        className: config.className,
        locale: localeData.locale,
      );
      buffer.writeln(
          'typedef $legacyClassName = ${config.className}; // ignore: unused_element');
      buffer.writeln(
          'class $finalClassName$mixinStr implements BaseTranslations<${config.enumName}, ${config.className}> {');
    } else {
      buffer.writeln('class $finalClassName$mixinStr {');
    }
  } else {
    // The class name of the **base** locale (path-dependent).
    final baseClassName = root
        ? config.className
        : getClassName(
            base: true,
            visibility: TranslationClassVisibility.public,
            parentName: className,
            locale: config.baseLocale,
          );
    if (config.fallbackStrategy == GenerateFallbackStrategy.none) {
      buffer.writeln(
          'class $finalClassName$mixinStr implements $baseClassName {');
    } else {
      buffer.writeln('class $finalClassName extends $baseClassName$mixinStr {');
    }
  }

  // constructor and custom fields
  final callSuperConstructor = !localeData.base &&
      config.fallbackStrategy == GenerateFallbackStrategy.baseLocale;
  if (root) {
    if (localeData.base && config.flutterIntegration && config.localeHandling) {
      buffer.writeln(
          '\t/// Returns the current translations of the given [context].');
      buffer.writeln('\t///');
      buffer.writeln('\t/// Usage:');
      buffer.writeln(
          '\t/// final ${config.translateVariable} = ${config.className}.of(context);');
      buffer.writeln(
        '\tstatic $finalClassName of(BuildContext context) => InheritedLocaleData.of<${config.enumName}, $finalClassName>(context).translations;',
      );
      buffer.writeln();
    }

    buffer.writeln(
        '\t/// You can call this constructor and build your own translation instance of this locale.');
    buffer.writeln(
        '\t/// Constructing via the enum [${config.enumName}.build] is preferred.');
    if (config.translationOverrides) {
      buffer.writeln(
          '\t/// [AppLocaleUtils.buildWithOverrides] is recommended for overriding.');
    }

    buffer.write(
        '\t$finalClassName({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<${config.enumName}, ${config.className}>? meta');

    buffer.writeln('})');
    if (!config.translationOverrides) {
      buffer.write(
          '\t\t: assert(overrides == null, \'Set "translation_overrides: true" in order to enable this feature.\'),\n\t\t  ');
    } else {
      buffer.write('\t\t: ');
    }

    buffer.writeln('\$meta = meta ?? TranslationMetadata(');

    buffer.writeln(
        '\t\t    locale: ${config.enumName}.${localeData.locale.enumConstant},');
    buffer.writeln('\t\t    overrides: overrides ?? {},');
    buffer.writeln('\t\t    cardinalResolver: cardinalResolver,');
    buffer.writeln('\t\t    ordinalResolver: ordinalResolver,');
    if (localeData.types.isNotEmpty) {
      buffer.writeln('\t\t    types: {');
      for (final entry in localeData.types.entries) {
        // trim NumberFormat.currency(symbol: '€', locale: 'en').format(value)
        // to NumberFormat.currency(symbol: '€', locale: 'en')
        // removing 14 characters
        buffer.writeln(
          '\t\t      \'${entry.key}\': ValueFormatter(() => ${entry.value.substring(0, entry.value.length - 14)}),',
        );
      }
      buffer.writeln('\t\t    },');
    }
    if (config.obfuscation.enabled) {
      final String method;
      final List<int> parts;
      if ((config.obfuscation.secret ^ localeData.locale.languageTag.hashCode) %
              2 ==
          0) {
        method = r'$calc0';
        parts = getParts0(config.obfuscation.secret);
      } else {
        method = r'$calc1';
        parts = getParts1(config.obfuscation.secret);
      }
      buffer.writeln('\t\t    s: $method(${parts.join(', ')}),');
    }
    buffer.write('\t\t  )');

    if (callSuperConstructor) {
      buffer.write(
          ',\n\t\t  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver)');
    }

    if (config.renderFlatMap) {
      buffer.writeln(' {');
      if (callSuperConstructor) {
        buffer.writeln(
            '\t\tsuper.\$meta.setFlatMapFunction(\$meta.getTranslation); // copy base translations to super.\$meta');
      }
      buffer.writeln('\t\t\$meta.setFlatMapFunction(_flatMapFunction);');
      buffer.writeln('\t}');
    } else {
      buffer.writeln(';');
    }

    buffer.writeln();
    buffer.writeln(
        '\t/// Metadata for the translations of <${localeData.locale.languageTag}>.');
    buffer.writeln(
        '\t@override final TranslationMetadata<${config.enumName}, ${config.className}> \$meta;');

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

      if (config.fallbackStrategy == GenerateFallbackStrategy.baseLocale &&
          !localeData.base) {
        buffer.writeln(' ?? super.\$meta.getTranslation(key);');
      } else {
        buffer.writeln(';');
      }
    }
  } else {
    if (callSuperConstructor) {
      buffer.writeln(
          '\t$finalClassName._($rootClassName root) : this._root = root, super.internal(root);');
    } else {
      if (config.fallbackStrategy == GenerateFallbackStrategy.baseLocale) {
        buffer.writeln('\t$finalClassName.internal(this._root);');
      } else {
        buffer.writeln('\t$finalClassName._(this._root);');
      }
    }
  }

  // root
  buffer.writeln();
  buffer.write('\t');

  if (root) {
    buffer.write('late final $rootClassName _root = this;');
  } else {
    buffer.write('final $rootClassName _root;');
  }
  buffer.writeln(' // ignore: unused_field');

  if (root) {
    buffer.writeln();
    if (!localeData.base) {
      buffer.writeln('\t@override ');
    }
    buffer.writeln(
        '\t$rootClassName \$copyWith({TranslationMetadata<${config.enumName}, ${config.className}>? meta}) => $rootClassName(meta: meta ?? this.\$meta);');
  }

  buffer.writeln();
  buffer.writeln('\t// Translations');

  bool prevHasComment = false;
  node.entries.forEach((key, value) {
    // comment handling
    final generateAutodoc =
        localeData.base && config.autodoc.enabled && value is LeafNode;
    if (value.comment != null || generateAutodoc) {
      if (value.comment != null) {
        // add comment add on the line above
        buffer.writeln();
        buffer.writeln('\t/// ${value.comment}');
      }

      if (generateAutodoc) {
        if (value.comment != null) {
          buffer.writeln('\t///');
        } else {
          buffer.writeln();
        }

        for (int i = 0; i < config.autodoc.locales.length; i++) {
          final locale = config.autodoc.locales[i];
          final String? autodoc;
          if (locale == AutodocConfig.base) {
            autodoc = localeData.getAutodoc('', value as LeafNode);
          } else {
            final localeData = allTranslations.firstWhereOrNull(
              (l) => l.locale.languageTag == locale,
            );

            if (localeData == null) {
              throw 'Locale "$locale" not found in translations.';
            }

            autodoc = localeData.getAutodoc(value.path, null);
          }

          if (autodoc != null) {
            if (i != 0) {
              buffer.writeln('\t///');
            }

            buffer.writeln(
              "\t/// ${locale == AutodocConfig.base ? localeData.locale.languageTag : locale}: '$autodoc'",
            );
            prevHasComment = true;
          }
        }
      }
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
            true) {
      buffer.write('@override ');
    }

    // even if this attribute exist, it has to satisfy the same signature as
    // specified in the interface
    // this error seems to occur when using in combination with "extends"
    final optional =
        config.fallbackStrategy == GenerateFallbackStrategy.baseLocale &&
                node.interface?.attributes.any((attribute) =>
                        attribute.optional && attribute.attributeName == key) ==
                    true
            ? '?'
            : '';

    if (value is StringTextNode) {
      final translationOverrides = config.translationOverrides
          ? 'TranslationOverrides.string(_root.\$meta, \'${value.path}\', ${_toParameterMap(value.params)}) ?? '
          : '';
      final stringLiteral = getStringLiteral(
          value.content, value.links.length, config.obfuscation);
      if (value.params.isEmpty) {
        buffer.writeln(
            'String$optional get $key => $translationOverrides$stringLiteral;');
      } else {
        buffer.writeln(
            'String$optional $key${_toParameterList(value.params, value.paramTypeMap)} => $translationOverrides$stringLiteral;');
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
        includeParameters: true,
        variableNameResolver: null,
        forceArrow: true,
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
        listName: key,
        depth: 0,
      );
    } else if (value is ObjectNode) {
      String childClassNoLocale = getClassName(
        base: localeData.base,
        visibility: config.translationClassVisibility,
        parentName: className,
        childName: key,
      );

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
          base: localeData.base,
          visibility: config.translationClassVisibility,
          parentName: className,
          childName: key,
          locale: localeData.locale,
        );

        buffer.write('late final $childClassWithLocale$optional $key = ');
        if (localeData.base &&
            config.fallbackStrategy == GenerateFallbackStrategy.baseLocale) {
          buffer.writeln('$childClassWithLocale.internal(_root);');
        } else {
          buffer.writeln('$childClassWithLocale._(_root);');
        }
      }
    } else if (value is PluralNode) {
      final returnType = value.rich ? 'TextSpan' : 'String';
      buffer.write('$returnType$optional $key');
      _addPluralCall(
        buffer: buffer,
        config: config,
        language: localeData.locale.language,
        node: value,
        depth: 0,
      );
    } else if (value is ContextNode) {
      final returnType = value.rich ? 'TextSpan' : 'String';
      buffer.write('$returnType$optional $key');
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

    // Note:
    // Maps cannot contain rich texts
    // because there is no way to add the "rich" modifier.
    if (value is StringTextNode) {
      final stringLiteral = getStringLiteral(
          value.content, value.links.length, config.obfuscation);
      if (value.params.isEmpty) {
        buffer.writeln('\'$key\': $stringLiteral,');
      } else {
        buffer.writeln(
            '\'$key\': ${_toParameterList(value.params, value.paramTypeMap)} => $stringLiteral,');
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
        listName: key,
        depth: depth + 1,
      );
    } else if (value is ObjectNode) {
      String childClassNoLocale = getClassName(
        base: base,
        visibility: config.translationClassVisibility,
        parentName: className,
        childName: key,
      );

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
        String childClassWithLocale = getClassName(
          base: base,
          visibility: config.translationClassVisibility,
          parentName: className,
          childName: key,
          locale: locale,
        );

        buffer.write('\'$key\': ');
        if (base &&
            config.fallbackStrategy == GenerateFallbackStrategy.baseLocale) {
          buffer.writeln('$childClassWithLocale.internal(_root),');
        } else {
          buffer.writeln('$childClassWithLocale._(_root),');
        }
      }
    } else if (value is PluralNode) {
      buffer.write('\'$key\': ');
      _addPluralCall(
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
  required String? listName,
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

    // Note:
    // Lists cannot contain rich texts
    // because there is no way to add the "rich" modifier.
    if (value is StringTextNode) {
      final stringLiteral = getStringLiteral(
          value.content, value.links.length, config.obfuscation);
      if (value.params.isEmpty) {
        buffer.writeln('$stringLiteral,');
      } else {
        buffer.writeln(
            '${_toParameterList(value.params, value.paramTypeMap)} => $stringLiteral,');
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
        listName: listName,
        depth: depth + 1,
      );
    } else if (value is ObjectNode) {
      final key = '\$${listName ?? ''}\$${depth.toString()}i${i.toString()}\$';
      final String childClassNoLocale = getClassName(
          base: base,
          visibility: config.translationClassVisibility,
          parentName: className,
          childName: key);

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
          base: base,
          visibility: config.translationClassVisibility,
          parentName: className,
          childName: key,
          locale: locale,
        );

        if (base &&
            config.fallbackStrategy == GenerateFallbackStrategy.baseLocale) {
          buffer.writeln('$childClassWithLocale.internal(_root),');
        } else {
          buffer.writeln('$childClassWithLocale._(_root),');
        }
      }
    } else if (value is PluralNode) {
      _addPluralCall(
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

void _addPluralCall({
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
  final paramTypeMap = <String, String>{};
  for (final textNode in textNodeList) {
    paramSet.addAll(textNode.params);
    paramTypeMap.addAll(textNode.paramTypeMap);
  }

  final builderParam = '${node.paramName}Builder';
  final params =
      paramSet.where((p) => p != node.paramName && p != builderParam).toList();

  // add plural parameter first
  buffer.write('({required ${node.paramType} ${node.paramName}');
  if (node.rich && paramSet.contains(node.paramName)) {
    // add builder parameter if it is used
    buffer.write(
        ', required InlineSpan Function(${node.paramType}) ${node.paramName}Builder');
  }
  for (int i = 0; i < params.length; i++) {
    buffer.write(', required ${paramTypeMap[params[i]] ?? 'Object'} ');
    buffer.write(params[i]);
  }

  // custom resolver has precedence
  final prefix = node.pluralType.name;
  buffer.write('}) => ');

  if (node.rich) {
    final translationOverrides = config.translationOverrides
        ? 'TranslationOverridesFlutter.richPlural(_root.\$meta, \'${node.path}\', ${_toParameterMap({
                ...params,
                node.paramName,
                '${node.paramName}Builder',
              })}) ?? '
        : '';
    buffer.writeln('${translationOverrides}RichPluralResolvers.bridge(');
    _addTabs(buffer, depth + 2);
    buffer.writeln('n: ${node.paramName},');
    _addTabs(buffer, depth + 2);
    buffer.writeln(
        'resolver: _root.\$meta.${prefix}Resolver ?? PluralResolvers.$prefix(\'$language\'),');
    for (final quantity in node.quantities.entries) {
      _addTabs(buffer, depth + 2);
      buffer.write('${quantity.key.paramName()}: () => ');

      _addRichTextCall(
        buffer: buffer,
        config: config,
        node: quantity.value as RichTextNode,
        includeParameters: false,
        variableNameResolver: (name) =>
            name == node.paramName ? '${node.paramName}Builder($name)' : name,
        forceArrow: false,
        depth: depth + 1,
      );
    }
  } else {
    final translationOverrides = config.translationOverrides
        ? 'TranslationOverrides.plural(_root.\$meta, \'${node.path}\', ${_toParameterMap({
                ...params,
                node.paramName,
              })}) ?? '
        : '';
    buffer.writeln(
        '$translationOverrides(_root.\$meta.${prefix}Resolver ?? PluralResolvers.$prefix(\'$language\'))(${node.paramName},');
    for (final quantity in node.quantities.entries) {
      _addTabs(buffer, depth + 2);
      final textNode = quantity.value as StringTextNode;
      buffer.writeln(
          '${quantity.key.paramName()}: ${getStringLiteral(textNode.content, textNode.links.length, config.obfuscation)},');
    }
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
  required bool includeParameters,
  required String Function(String variableName)? variableNameResolver,
  required bool forceArrow,
  required int depth,
  bool forceSemicolon = false,
}) {
  if (includeParameters) {
    if (node.params.isNotEmpty) {
      buffer.write(_toParameterList(node.params, node.paramTypeMap));
    }

    if (node.params.isNotEmpty || forceArrow) {
      buffer.write(' => ');
    }

    if (config.translationOverrides) {
      buffer.write(
          'TranslationOverridesFlutter.rich(_root.\$meta, \'${node.path}\', ${_toParameterMap(node.params)}) ?? ');
    }
  }

  buffer.writeln('TextSpan(children: [');
  for (final span in node.spans) {
    _addTabs(buffer, depth + 2);

    if (span is LiteralSpan) {
      buffer.write(
        "${!config.obfuscation.enabled && span.isConstant ? 'const ' : ''}TextSpan(text: ${getStringLiteral(span.literal, span.links.length, config.obfuscation)})",
      );
    } else if (span is VariableSpan) {
      if (variableNameResolver != null) {
        buffer.write(variableNameResolver(span.variableName));
      } else {
        buffer.write(span.variableName);
      }
    } else if (span is FunctionSpan) {
      buffer.write(
        '${span.functionName}(${getStringLiteral(span.arg, span.links.length, config.obfuscation)})',
      );
    }
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

  // parameters are union sets over all context forms
  final paramSet = <String>{};
  final paramTypeMap = <String, String>{};
  for (final textNode in textNodeList) {
    paramSet.addAll(textNode.params);
    paramTypeMap.addAll(textNode.paramTypeMap);
  }
  final params = paramSet.where((p) => p != node.paramName).toList();

  // parameters with context as first parameter
  buffer.write('({required ${node.context.enumName} ${node.paramName}');
  if (node.rich && paramSet.contains(node.paramName)) {
    // add builder parameter if it is used
    buffer.write(
        ', required InlineSpan Function(${node.context.enumName}) ${node.paramName}Builder');
  }
  for (int i = 0; i < params.length; i++) {
    buffer.write(', required ${paramTypeMap[params[i]] ?? 'Object'} ');
    buffer.write(params[i]);
  }
  buffer.writeln('}) {');

  if (config.translationOverrides) {
    final functionCall = node.rich
        ? 'TranslationOverridesFlutter.richContext<${node.context.enumName}>'
        : 'TranslationOverrides.context';

    _addTabs(buffer, depth + 2);
    buffer.writeln(
        'final override = $functionCall(_root.\$meta, \'${node.path}\', ${_toParameterMap({
          ...params,
          node.paramName,
          if (node.rich) '${node.paramName}Builder',
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
    buffer.writeln('case ${node.context.enumName}.${entry.key}:');
    _addTabs(buffer, depth + 4);
    buffer.write('return ');
    if (node.rich) {
      _addRichTextCall(
        buffer: buffer,
        config: config,
        node: entry.value as RichTextNode,
        includeParameters: false,
        variableNameResolver: (name) =>
            name == node.paramName ? '${node.paramName}Builder($name)' : name,
        forceArrow: false,
        depth: depth + 3,
        forceSemicolon: true,
      );
    } else {
      final textNode = entry.value as StringTextNode;
      buffer.writeln(
        '${getStringLiteral(textNode.content, textNode.links.length, config.obfuscation)};',
      );
    }
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
