import 'package:slang/src/builder/builder/text/l10n_parser.dart';
import 'package:slang/src/builder/builder/text/param_parser.dart';
import 'package:slang/src/builder/builder/translation_model_builder.dart';
import 'package:slang/src/builder/model/context_type.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/interface.dart';
import 'package:slang/src/builder/model/pluralization.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';
import 'package:slang/src/builder/utils/string_interpolation_extensions.dart';

class NodeModifiers {
  /// Flag. Mark a node as rich text
  static const rich = 'rich';

  /// Flag. Mark a node as a map
  static const map = 'map';

  /// Flag. Missing keys should fallback to base map.
  /// Only relevant when fallback_strategy is configured.
  static const fallback = 'fallback';

  /// Flag. Mark a plural as plural
  static const plural = 'plural';

  /// Flag. Mark a plural as cardinal
  static const cardinal = 'cardinal';

  /// Flag. Mark a plural as ordinal
  static const ordinal = 'ordinal';

  /// Parameter. Set context name.
  static const context = 'context';

  /// Parameter. Set a parameter name for a plural or context
  static const param = 'param';

  /// Flag. Mark all children of an interface as descendants of an interface
  static const interface = 'interface';

  /// Flag. Mark a single JSON object as a descendant of an interface
  static const singleInterface = 'singleInterface';

  /// Analysis flag. Ignore during missing translation analysis
  static const ignoreMissing = 'ignoreMissing';

  /// Analysis flag. Ignore during unused translation analysis
  static const ignoreUnused = 'ignoreUnused';

  /// Analysis flag. Translation is outdated
  static const outdated = 'OUTDATED';
}

/// the super class of every node
abstract class Node {
  static const keyDelimiter = ','; // used by plural or context

  final String path;
  final String rawPath; // including modifiers
  final Map<String, String> modifiers;
  final String? comment;
  Node? _parent;

  Node? get parent => _parent;

  Node({
    required this.path,
    required this.rawPath,
    required this.modifiers,
    required this.comment,
  });

  void setParent(Node parent) {
    assert(_parent == null);
    _parent = parent;
  }

  /// Deep clones the node.
  Node clone({
    required bool keepParent,
    I18nLocale? locale,
  });
}

/// Flag for leaves
/// Leaves are: [TextNode], [PluralNode] and [ContextNode]
abstract interface class LeafNode {}

/// The super class for [ListNode] and [ObjectNode]
abstract class IterableNode extends Node {
  /// The generic type of the container, i.e. `Map<String, T>` or `List<T>`
  String _genericType;

  String get genericType => _genericType;

  /// Child nodes.
  /// This is just an alias so we can iterate more easily.
  Iterable<Node> get values;

  IterableNode({
    required super.path,
    required super.rawPath,
    required super.modifiers,
    required super.comment,
    required String genericType,
  }) : _genericType = genericType;

  void setGenericType(String genericType) {
    _genericType = genericType;
  }
}

class ObjectNode extends IterableNode {
  final Map<String, Node> entries;
  final bool isMap;

  /// If not null, then this node has an interface (mixin)
  Interface? _interface;

  Interface? get interface => _interface;

  @override
  Iterable<Node> get values => entries.values;

  ObjectNode({
    required super.path,
    required super.rawPath,
    required super.modifiers,
    required super.comment,
    required this.entries,
    required this.isMap,
  }) : super(genericType: _determineGenericType(entries.values));

  void setInterface(Interface interface) {
    _interface = interface;
  }

  @override
  String toString() => entries.toString();

  @override
  ObjectNode clone({required bool keepParent, I18nLocale? locale}) {
    final node = ObjectNode(
      path: path,
      rawPath: rawPath,
      modifiers: modifiers,
      comment: comment,
      entries: entries.map(
        (key, value) => MapEntry(
          key,
          value.clone(keepParent: keepParent, locale: locale),
        ),
      ),
      isMap: isMap,
    );
    if (keepParent && parent != null) {
      node.setParent(parent!);
    }
    node.setGenericType(genericType);
    if (interface != null) {
      node.setInterface(interface!);
    }
    return node;
  }
}

class ListNode extends IterableNode {
  final List<Node> entries;

  @override
  Iterable<Node> get values => entries;

  ListNode({
    required super.path,
    required super.rawPath,
    required super.comment,
    required super.modifiers,
    required this.entries,
  }) : super(genericType: _determineGenericType(entries));

  @override
  String toString() => entries.toString();

  @override
  ListNode clone({required bool keepParent, I18nLocale? locale}) {
    final node = ListNode(
      path: path,
      rawPath: rawPath,
      modifiers: modifiers,
      comment: comment,
      entries: entries
          .map((e) => e.clone(keepParent: keepParent, locale: locale))
          .toList(),
    );

    if (keepParent && parent != null) {
      node.setParent(parent!);
    }

    node.setGenericType(genericType);

    return node;
  }
}

enum PluralType {
  cardinal,
  ordinal,
}

class PluralNode extends Node implements LeafNode {
  final PluralType pluralType;
  final Map<Quantity, TextNode> quantities;
  final String paramName; // name of the plural parameter
  final String paramType; // type of the plural parameter defaults to num
  final bool rich;

  PluralNode({
    required super.path,
    required super.rawPath,
    required super.modifiers,
    required super.comment,
    required this.pluralType,
    required this.quantities,
    required this.paramName,
    required this.paramType,
    required this.rich,
  });

  Set<AttributeParameter> getParameters() {
    final paramSet = <String>{};
    final paramTypeMap = <String, String>{};
    for (final textNode in quantities.values) {
      paramSet.addAll(textNode.params);
      paramTypeMap.addAll(textNode.paramTypeMap);
    }
    paramSet.add(paramName);
    paramTypeMap[paramName] = paramType;
    if (rich) {
      final builderParam = '${paramName}Builder';
      paramSet.add(builderParam);
      paramTypeMap[builderParam] = 'InlineSpan Function($paramType)';
    }
    return paramSet.map((param) {
      return AttributeParameter(
        parameterName: param,
        type: paramTypeMap[param] ?? 'Object',
      );
    }).toSet();
  }

  @override
  String toString() => quantities.toString();

  @override
  PluralNode clone({required bool keepParent, I18nLocale? locale}) {
    final node = PluralNode(
      path: path,
      rawPath: rawPath,
      modifiers: modifiers,
      comment: comment,
      pluralType: pluralType,
      quantities: quantities.map(
        (key, value) => MapEntry(
          key,
          value.clone(keepParent: keepParent, locale: locale),
        ),
      ),
      paramName: paramName,
      paramType: paramType,
      rich: rich,
    );

    if (keepParent && parent != null) {
      node.setParent(parent!);
    }

    return node;
  }
}

class ContextNode extends Node implements LeafNode {
  final PendingContextType context;
  final Map<String, TextNode> entries;
  final String paramName; // name of the context parameter
  final bool rich;

  ContextNode({
    required super.path,
    required super.rawPath,
    required super.modifiers,
    required super.comment,
    required this.context,
    required this.entries,
    required this.paramName,
    required this.rich,
  });

  Set<AttributeParameter> getParameters() {
    final paramSet = <String>{};
    final paramTypeMap = <String, String>{};
    for (final textNode in entries.values) {
      paramSet.addAll(textNode.params);
      paramTypeMap.addAll(textNode.paramTypeMap);
    }
    paramSet.add(paramName);
    paramTypeMap[paramName] = context.enumName;
    if (rich) {
      final builderParam = '${paramName}Builder';
      paramSet.add(builderParam);
      paramTypeMap[builderParam] = 'InlineSpan Function(${context.enumName})';
    }
    return paramSet.map((param) {
      return AttributeParameter(
          parameterName: param, type: paramTypeMap[param] ?? 'Object');
    }).toSet();
  }

  @override
  String toString() => entries.toString();

  @override
  ContextNode clone({required bool keepParent, I18nLocale? locale}) {
    final node = ContextNode(
      path: path,
      rawPath: rawPath,
      modifiers: modifiers,
      comment: comment,
      context: context,
      entries: entries.map(
        (key, value) => MapEntry(
          key,
          value.clone(keepParent: keepParent, locale: locale),
        ),
      ),
      paramName: paramName,
      rich: rich,
    );

    if (keepParent && parent != null) {
      node.setParent(parent!);
    }

    return node;
  }
}

abstract class TextNode extends Node implements LeafNode {
  /// The locale of the text node
  final I18nLocale locale;

  /// User-defined types for the locale
  final Map<String, FormatTypeInfo> types;

  /// The original string
  final String raw;

  /// Set of parameters.
  /// Hello {name}, I am {age} years old -> {'name', 'age'}
  Set<String> get params;

  /// Plural and context parameters need to have a special parameter type (e.g. num)
  /// In a normal case, this parameter and its type will be added at generate stage
  ///
  /// For special cases, i.e. a translation is linked to a plural translation,
  /// the type must be specified and cannot be [Object].
  Map<String, String> get paramTypeMap;

  /// Set of paths to [TextNode]s
  /// Will be used for 2nd round, determining the final set of parameters
  Set<String> get links;

  /// Several configs, persisted into node to make it easier to copy
  /// See [updateWithLinkParams]
  final bool shouldEscape;
  final bool handleTypes;
  final StringInterpolation interpolation;
  final CaseStyle? paramCase;

  TextNode({
    required super.path,
    required super.rawPath,
    required super.modifiers,
    required super.comment,
    required this.locale,
    required this.types,
    required this.raw,
    required this.shouldEscape,
    required this.handleTypes,
    required this.interpolation,
    required this.paramCase,
  });

  /// Updates [content], [params] and [paramTypeMap]
  /// according to the new linked parameters
  void updateWithLinkParams({
    required Map<String, Set<String>> linkParamMap,
    required Map<String, String> paramTypeMap,
  });

  @override
  TextNode clone({
    required bool keepParent,
    I18nLocale? locale,
  });
}

class StringTextNode extends TextNode {
  /// Content of the text node, normalized.
  /// Will be written to .g.dart as is.
  late String _content;

  String get content => _content;

  late Set<String> _params;

  @override
  Set<String> get params => _params;

  late Set<String> _links;

  @override
  Set<String> get links => _links;

  Map<String, String> _paramTypeMap = <String, String>{};

  @override
  Map<String, String> get paramTypeMap => _paramTypeMap;

  StringTextNode({
    required super.path,
    required super.rawPath,
    required super.modifiers,
    required super.locale,
    required super.types,
    required super.raw,
    required super.comment,
    required super.shouldEscape,
    required super.handleTypes,
    required super.interpolation,
    required super.paramCase,
    Map<String, Set<String>>? linkParamMap,
  }) {
    final parsedResult = _parseInterpolation(
      locale: locale,
      types: types,
      raw: shouldEscape ? _escapeContent(raw, interpolation) : raw,
      interpolation: interpolation,
      defaultType: 'Object',
      paramCase: paramCase,
      digestParameter: handleTypes && true,
    );
    _params = parsedResult.params.keys.toSet();
    _paramTypeMap.addAll(parsedResult.params);

    if (linkParamMap != null) {
      _params.addAll(linkParamMap.values.expand((e) => e));
    }

    final parsedLinksResult = _parseLinks(
      input: parsedResult.parsedContent,
      linkParamMap: linkParamMap,
    );

    _links = parsedLinksResult.links;
    _content = parsedLinksResult.parsedContent;
  }

  @override
  void updateWithLinkParams({
    required Map<String, Set<String>> linkParamMap,
    required Map<String, String> paramTypeMap,
  }) {
    _paramTypeMap = paramTypeMap;
    _params.addAll(linkParamMap.values.expand((e) => e));

    // build a temporary TextNode to get the updated content
    final temp = StringTextNode(
      path: path,
      rawPath: rawPath,
      modifiers: modifiers,
      locale: locale,
      types: types,
      raw: raw,
      comment: comment,
      shouldEscape: shouldEscape,
      handleTypes: handleTypes,
      interpolation: interpolation,
      paramCase: paramCase,
      linkParamMap: linkParamMap,
    );

    _content = temp.content;
  }

  @override
  String toString() {
    if (params.isEmpty) {
      return content;
    } else {
      return '$params => $content';
    }
  }

  @override
  StringTextNode clone({required bool keepParent, I18nLocale? locale}) {
    final node = StringTextNode(
      path: path,
      rawPath: rawPath,
      modifiers: modifiers,
      locale: locale ?? this.locale,
      types: types,
      raw: raw,
      comment: comment,
      shouldEscape: shouldEscape,
      handleTypes: handleTypes,
      interpolation: interpolation,
      paramCase: paramCase,
    );

    if (keepParent && parent != null) {
      node.setParent(parent!);
    }

    return node;
  }
}

class RichTextNode extends TextNode {
  late List<BaseSpan> _spans;

  List<BaseSpan> get spans => _spans;

  late Set<String> _params;

  @override
  Set<String> get params => _params;

  late Set<String> _links;

  @override
  Set<String> get links => _links;

  final Map<String, String> _paramTypeMap = <String, String>{};

  @override
  Map<String, String> get paramTypeMap => _paramTypeMap;

  RichTextNode({
    required super.path,
    required super.rawPath,
    required super.modifiers,
    required super.locale,
    required super.types,
    required super.raw,
    required super.comment,
    required super.shouldEscape,
    required super.handleTypes,
    required super.interpolation,
    required super.paramCase,
    Map<String, Set<String>>? linkParamMap,
  }) {
    final rawParsedResult = _parseInterpolation(
      locale: locale,
      types: types,
      raw: shouldEscape ? _escapeContent(raw, interpolation) : raw,
      interpolation: interpolation,
      defaultType: 'ignored',
      // types are ignored
      paramCase: null,
      // param case will be applied later
      digestParameter: false,
    );

    _params = <String>{};
    for (final key in rawParsedResult.params.keys) {
      final parsedParam = parseParamWithArg(
        rawParam: key,
        paramCase: paramCase,
      );
      _params.add(parsedParam.paramName);
      _paramTypeMap[parsedParam.paramName] =
          parsedParam.arg == null ? 'InlineSpan' : 'InlineSpanBuilder';
    }

    if (linkParamMap != null) {
      _params.addAll(linkParamMap.values.expand((e) => e));
    }

    _links = {};
    _spans = _splitWithMatchAndNonMatch(
      rawParsedResult.parsedContent,
      RegexUtils.argumentsDartRegex,
      onNonMatch: (text) {
        final parsedLinksResult = _parseLinks(
          input: text,
          linkParamMap: linkParamMap,
        );
        _links.addAll(parsedLinksResult.links);
        return LiteralSpan(
          literal: parsedLinksResult.parsedContent,
          isConstant: parsedLinksResult.links.isEmpty,
          links: parsedLinksResult.links,
        );
      },
      onMatch: (match) {
        final parsed = parseParamWithArg(
          rawParam: (match.group(1) ?? match.group(2))!,
          paramCase: paramCase,
        );
        final parsedArg = parsed.arg;
        if (parsedArg != null) {
          final parsedLinksResult = _parseLinks(
            input: parsedArg,
            linkParamMap: linkParamMap,
          );
          _links.addAll(parsedLinksResult.links);
          return FunctionSpan(
            functionName: parsed.paramName,
            arg: parsedLinksResult.parsedContent,
            links: parsedLinksResult.links,
          );
        } else {
          return VariableSpan(parsed.paramName);
        }
      },
    ).toList();
  }

  @override
  void updateWithLinkParams({
    required Map<String, Set<String>> linkParamMap,
    required Map<String, String> paramTypeMap,
  }) {
    _paramTypeMap.addAll(paramTypeMap);
    _params.addAll(linkParamMap.values.expand((e) => e));

    // build a temporary TextNode to get the updated content
    final temp = RichTextNode(
      path: path,
      rawPath: rawPath,
      modifiers: modifiers,
      locale: locale,
      types: types,
      raw: raw,
      comment: comment,
      shouldEscape: shouldEscape,
      handleTypes: handleTypes,
      interpolation: interpolation,
      paramCase: paramCase,
      linkParamMap: linkParamMap,
    );

    _spans = temp.spans;
  }

  @override
  RichTextNode clone({required bool keepParent, I18nLocale? locale}) {
    final node = RichTextNode(
      path: path,
      rawPath: rawPath,
      modifiers: modifiers,
      locale: locale ?? this.locale,
      types: types,
      raw: raw,
      comment: comment,
      shouldEscape: shouldEscape,
      handleTypes: handleTypes,
      interpolation: interpolation,
      paramCase: paramCase,
    );

    if (keepParent && parent != null) {
      node.setParent(parent!);
    }

    return node;
  }
}

String _escapeContent(String raw, StringInterpolation interpolation) {
  final escapedRaw = raw
      .replaceAll('\r\n', '\\n') // CRLF -> \n
      .replaceAll('\n', '\\n') // LF -> \n
      .replaceAll('\'', '\\\''); // ' -> \'

  if (interpolation == StringInterpolation.dart) {
    // escape single $
    return escapedRaw.replaceAllMapped(RegexUtils.dollarOnlyRegex, (match) {
      String result = '';
      if (match.group(1) != null) {
        result += match.group(1)!; // pre character
      }
      result += '\\\$';
      if (match.group(2) != null) {
        result += match.group(2)!; // post character
      }
      return result;
    });
  } else {
    // escape any $ with \$
    return escapedRaw.replaceAllMapped(RegexUtils.dollarRegex, (match) {
      if (match.group(1) != null) {
        return '${match.group(1)}\\\$'; // with pre character
      } else {
        return '\\\$';
      }
    });
  }
}

class _ParseInterpolationResult {
  final String parsedContent;

  /// Map of parameter name -> parameter type
  final Map<String, String> params;

  /// Map of parameter name -> parameter format
  final Map<String, String> formats;

  _ParseInterpolationResult({
    required this.parsedContent,
    required this.params,
    required this.formats,
  });

  @override
  String toString() =>
      '_ParseInterpolationResult(parsedContent: $parsedContent, params: $params, formats: $formats)';
}

_ParseInterpolationResult _parseInterpolation({
  required I18nLocale locale,
  required Map<String, FormatTypeInfo> types,
  required String raw,
  required StringInterpolation interpolation,
  required String defaultType,
  required CaseStyle? paramCase,
  required bool digestParameter,
}) {
  final String parsedContent;
  final params = <String, String>{};
  final formats = <String, String>{};

  String convertInnerParam(String inner) {
    if (!digestParameter) {
      params[inner] = 'is ignored';
      return '\${$inner}';
    }

    final parsedParam = parseParam(
      rawParam: inner,
      defaultType: defaultType,
      caseStyle: paramCase,
    );

    final existingType = types[parsedParam.paramType];
    if (existingType != null) {
      params[parsedParam.paramName] = existingType.paramType;
      return '\${_root.\$meta.types[\'${parsedParam.paramType}\']!.format(${parsedParam.paramName})}';
    }

    final parsedL10n = parseL10n(
      locale: locale,
      paramName: parsedParam.paramName,
      type: parsedParam.paramType.replaceAll(r"\'", "'"), // unescape
    );

    if (parsedL10n != null) {
      params[parsedParam.paramName] = parsedL10n.paramType;
      formats[parsedParam.paramName] = parsedL10n.format;
      return '\${${parsedL10n.format}}';
    } else {
      params[parsedParam.paramName] = parsedParam.paramType;
      return '\${${parsedParam.paramName}}';
    }
  }

  switch (interpolation) {
    case StringInterpolation.dart:
      parsedContent = raw.replaceDartInterpolation(replacer: (match) {
        final rawParam = match.startsWith(r'${')
            ? match.substring(2, match.length - 1)
            : match.substring(1, match.length);
        return convertInnerParam(rawParam);
      });
      break;
    case StringInterpolation.braces:
      parsedContent = raw.replaceBracesInterpolation(replacer: (match) {
        final rawParam = match.substring(1, match.length - 1);
        return convertInnerParam(rawParam);
      });
      break;
    case StringInterpolation.doubleBraces:
      parsedContent = raw.replaceDoubleBracesInterpolation(replacer: (match) {
        final rawParam = match.substring(2, match.length - 2);
        return convertInnerParam(rawParam);
      });
  }

  return _ParseInterpolationResult(
    parsedContent: parsedContent,
    params: params,
    formats: formats,
  );
}

class _ParseLinksResult {
  final String parsedContent;
  final Set<String> links;

  _ParseLinksResult(this.parsedContent, this.links);

  @override
  String toString() =>
      '_ParseLinksResult{parsedContent: $parsedContent, links: $links}';
}

_ParseLinksResult _parseLinks({
  required String input,
  required Map<String, Set<String>>? linkParamMap,
}) {
  final links = <String>{};
  final parsedContent = input.replaceAllMapped(RegexUtils.linkedRegex, (match) {
    final linkedPath = (match.group(1) ?? match.group(2))!;
    links.add(linkedPath);

    if (linkParamMap == null) {
      // assume no parameters
      return '\${_root.$linkedPath}';
    }

    final linkedParams = linkParamMap[linkedPath]!;
    if (linkedParams.isEmpty) {
      return '\${_root.$linkedPath}';
    }

    final parameterString =
        linkedParams.map((param) => '$param: $param').join(', ');
    return '\${_root.$linkedPath($parameterString)}';
  });
  return _ParseLinksResult(parsedContent, links);
}

Iterable<T> _splitWithMatchAndNonMatch<T>(
  String s,
  Pattern pattern, {
  required T Function(String) onNonMatch,
  required T Function(Match) onMatch,
}) sync* {
  final matches = pattern.allMatches(s).toList();
  final nonMatches = s.split(pattern);
  assert(matches.length == nonMatches.length - 1);
  for (var i = 0; i < matches.length; ++i) {
    if (nonMatches[i].isNotEmpty) {
      yield onNonMatch(nonMatches[i]);
    }
    yield onMatch(matches[i]);
  }
  if (nonMatches.last.isNotEmpty) {
    yield onNonMatch(nonMatches.last);
  }
}

abstract class BaseSpan {}

class LiteralSpan extends BaseSpan {
  final String literal;
  final bool isConstant;
  final Set<String> links;

  LiteralSpan({
    required this.literal,
    required this.isConstant,
    required this.links,
  });
}

class FunctionSpan extends BaseSpan {
  final String functionName;
  final String arg;
  final Set<String> links;

  FunctionSpan({
    required this.functionName,
    required this.arg,
    required this.links,
  });
}

class VariableSpan extends BaseSpan {
  final String variableName;

  VariableSpan(this.variableName);
}

String _determineGenericType(Iterable<Node> entries) {
  if (entries
      .every((child) => child is StringTextNode && child.params.isEmpty)) {
    return 'String';
  }
  if (entries.every((child) => child is ListNode)) {
    String? childGenericType = (entries.first as ListNode).genericType;
    for (final child in entries) {
      if (childGenericType != (child as ListNode).genericType) {
        childGenericType = 'dynamic'; // default
      }
    }
    return 'List<$childGenericType>'; // all lists have the same generic type
  }
  if (entries.every((child) => child is ObjectNode && child.isMap)) {
    String? childGenericType = (entries.first as ObjectNode).genericType;
    for (final child in entries) {
      if (childGenericType != (child as ObjectNode).genericType) {
        childGenericType = 'dynamic'; // default
      }
    }
    return 'Map<String, $childGenericType>'; // all maps have same generics
  }
  return 'dynamic';
}
