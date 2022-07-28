import 'package:slang/builder/model/build_config.dart';
import 'package:slang/builder/model/context_type.dart';
import 'package:slang/builder/model/interface.dart';
import 'package:slang/builder/model/pluralization.dart';
import 'package:slang/builder/utils/string_extensions.dart';
import 'package:slang/builder/utils/regex_utils.dart';

/// the super class of every node
abstract class Node {
  static const KEY_DELIMITER = ','; // used by plural or context

  final String path;
  final String? comment;
  Node? _parent;

  Node? get parent => _parent;

  Node({
    required this.path,
    required this.comment,
  });

  void setParent(Node parent) {
    assert(_parent == null);
    _parent = parent;
  }
}

/// Flag for leaves
/// Leaves are: TextNode, PluralNode and ContextNode
abstract class LeafNode {}

/// the super class for list and object nodes
abstract class IterableNode extends Node {
  /// If not null, then all its children have a specific interface.
  /// This overwrites the [plainStrings] attribute.
  String _genericType;

  String get genericType => _genericType;

  IterableNode({
    required super.path,
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

  ObjectNode({
    required super.path,
    required super.comment,
    required this.entries,
    required this.isMap,
  }) : super(genericType: _determineGenericType(entries.values));

  void setInterface(Interface interface) {
    _interface = interface;
  }

  @override
  String toString() => entries.toString();
}

class ListNode extends IterableNode {
  final List<Node> entries;

  ListNode({
    required super.path,
    required super.comment,
    required this.entries,
  }) : super(genericType: _determineGenericType(entries));

  @override
  String toString() => entries.toString();
}

enum PluralType {
  cardinal,
  ordinal,
}

class PluralNode extends Node implements LeafNode {
  final PluralType pluralType;
  final Map<Quantity, StringTextNode> quantities;
  final String paramName; // name of the plural parameter

  PluralNode({
    required super.path,
    required super.comment,
    required this.pluralType,
    required this.quantities,
    required String? parameterName,
  }) : this.paramName = parameterName ?? 'count';

  @override
  String toString() => quantities.toString();
}

class ContextNode extends Node implements LeafNode {
  final ContextType context;
  final Map<String, StringTextNode> entries;
  final String paramName; // name of the context parameter

  ContextNode({
    required super.path,
    required super.comment,
    required this.context,
    required this.entries,
    required this.paramName,
  });

  @override
  String toString() => entries.toString();
}

abstract class TextNode extends Node implements LeafNode {
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
  final StringInterpolation interpolation;
  final CaseStyle? paramCase;

  TextNode({
    required super.path,
    required super.comment,
    required this.raw,
    required this.interpolation,
    required this.paramCase,
  });

  /// Updates [content], [params] and [paramTypeMap]
  /// according to the new linked parameters
  void updateWithLinkParams({
    required Map<String, Set<String>> linkParamMap,
    required Map<String, String> paramTypeMap,
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
    required super.raw,
    required super.comment,
    required super.interpolation,
    required super.paramCase,
    Map<String, Set<String>>? linkParamMap,
  }) {
    final parsedResult = _parseInterpolation(
      raw: _escapeContent(raw, interpolation),
      interpolation: interpolation,
      paramCase: paramCase,
    );
    _params = parsedResult.params;

    if (linkParamMap != null) {
      _params.addAll(linkParamMap.values.expand((e) => e));
    }

    final parsedLinksResult = _parseLinks(
      input: parsedResult.parsedContent,
      linkParamMap: linkParamMap,
    );

    this._links = parsedLinksResult.links;
    this._content = parsedLinksResult.parsedContent;
  }

  @override
  void updateWithLinkParams({
    required Map<String, Set<String>> linkParamMap,
    required Map<String, String> paramTypeMap,
  }) {
    this._paramTypeMap = paramTypeMap;
    this._params.addAll(linkParamMap.values.expand((e) => e));

    // build a temporary TextNode to get the updated content
    final temp = StringTextNode(
      path: path,
      raw: raw,
      comment: comment,
      interpolation: interpolation,
      paramCase: paramCase,
      linkParamMap: linkParamMap,
    );

    this._content = temp.content;
  }

  @override
  String toString() {
    if (params.isEmpty) {
      return content;
    } else {
      return '$params => $content';
    }
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

  Map<String, String> _paramTypeMap = <String, String>{};
  @override
  Map<String, String> get paramTypeMap => _paramTypeMap;

  RichTextNode({
    required super.path,
    required super.raw,
    required super.comment,
    required super.interpolation,
    required super.paramCase,
    Map<String, Set<String>>? linkParamMap,
  }) {
    final rawParsedResult = _parseInterpolation(
      raw: _escapeContent(raw, interpolation),
      interpolation: interpolation,
      paramCase: paramCase,
      allowBracketsInsideParameters: true,
    );

    final parsedParams =
        rawParsedResult.params.map(_parseParamWithArg).toList();
    _params = parsedParams.map((e) => e.paramName).toSet();
    if (linkParamMap != null) {
      _params.addAll(linkParamMap.values.expand((e) => e));
    }

    _paramTypeMap = {
      for (final p in parsedParams)
        p.paramName: (p.arg != null ? 'InlineSpanBuilder' : 'InlineSpan'),
    };

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
        );
      },
      onMatch: (match) {
        final parsed = _parseParamWithArg((match.group(1) ?? match.group(2))!);
        final parsedArg = parsed.arg;
        if (parsedArg != null) return FunctionSpan(parsed.paramName, parsedArg);
        return VariableSpan(parsed.paramName);
      },
    ).toList();
  }

  @override
  void updateWithLinkParams({
    required Map<String, Set<String>> linkParamMap,
    required Map<String, String> paramTypeMap,
  }) {
    this._paramTypeMap.addAll(paramTypeMap);
    this._params.addAll(linkParamMap.values.expand((e) => e));

    // build a temporary TextNode to get the updated content
    final temp = RichTextNode(
      path: path,
      raw: raw,
      comment: comment,
      interpolation: interpolation,
      paramCase: paramCase,
      linkParamMap: linkParamMap,
    );

    this._spans = temp.spans;
  }
}

String _escapeContent(String raw, StringInterpolation interpolation) {
  final escapedRaw = raw
      .replaceAll('\r\n', '\\n') // (linebreak 1) -> \n
      .replaceAll('\n', '\\n') // (linebreak 2) -> \n
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
  final Set<String> params;

  _ParseInterpolationResult(this.parsedContent, this.params);

  @override
  String toString() =>
      '_ParseInterpolationResult{parsedContent: $parsedContent, params: $params}';
}

_ParseInterpolationResult _parseInterpolation({
  required String raw,
  required StringInterpolation interpolation,
  required CaseStyle? paramCase,
  bool allowBracketsInsideParameters = false,
}) {
  final String parsedContent;
  final params = Set<String>();

  switch (interpolation) {
    case StringInterpolation.dart:
      parsedContent =
          raw.replaceAllMapped(RegexUtils.argumentsDartRegex, (match) {
        final paramOriginal = (match.group(1) ?? match.group(2))!;
        if (paramCase == null) {
          // no transformations
          params.add(paramOriginal);
          return match.group(0)!;
        } else {
          // apply param case
          final paramWithCase = paramOriginal.toCase(paramCase);
          params.add(paramWithCase);
          return match.group(0)!.replaceAll(paramOriginal, paramWithCase);
        }
      });
      break;
    case StringInterpolation.braces:
      parsedContent = raw.replaceAllMapped(
          allowBracketsInsideParameters
              ? RegexUtils.argumentsBracesAdvancedRegex
              : RegexUtils.argumentsBracesRegex, (match) {
        if (match.group(1) == '\\') {
          return '{${match.group(2)}}'; // escape
        }

        final param = match.group(2)!.toCase(paramCase);
        params.add(param);

        if (match.group(3) != null || param.contains('(')) {
          // ${...} because a word follows
          // ... or contains brackets '(' which is needed for rich text, otherwise this would be invalid syntax anyways
          return '${match.group(1)}\${$param}${match.group(3) ?? ''}';
        } else {
          // $...
          return '${match.group(1)}\$$param';
        }
      });
      break;
    case StringInterpolation.doubleBraces:
      parsedContent = raw.replaceAllMapped(
          allowBracketsInsideParameters
              ? RegexUtils.argumentsDoubleBracesAdvancedRegex
              : RegexUtils.argumentsDoubleBracesRegex, (match) {
        if (match.group(1) == '\\') {
          return '{{${match.group(2)}}}'; // escape
        }

        final param = match.group(2)!.toCase(paramCase);
        params.add(param);

        if (match.group(3) != null || param.contains('(')) {
          // ${...} because a word follows
          // ... or contains brackets '(' which is needed for rich text, otherwise this would be invalid syntax anyways
          return '${match.group(1)}\${$param}${match.group(3) ?? ''}';
        } else {
          // $...
          return '${match.group(1)}\$$param';
        }
      });
  }

  return _ParseInterpolationResult(parsedContent, params);
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
  final links = Set<String>();
  final parsedContent = input.replaceAllMapped(RegexUtils.linkedRegex, (match) {
    final linkedPath = match.group(1)!;
    links.add(linkedPath);

    if (linkParamMap == null) {
      // assume no parameters
      return '\${_root.$linkedPath}';
    }

    final linkedParams = linkParamMap[linkedPath]!;
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

_ParamWithArg _parseParamWithArg(String src) {
  final match = RegexUtils.paramWithArg.firstMatch(src)!;
  return _ParamWithArg(match.group(1)!, match.group(3));
}

class _ParamWithArg {
  final String paramName;
  final String? arg;

  _ParamWithArg(this.paramName, this.arg);

  @override
  String toString() => '_ParamWithArg{paramName: $paramName, arg: $arg}';
}

abstract class BaseSpan {
  String get code;
}

class LiteralSpan extends BaseSpan {
  final String literal;
  final bool isConstant;

  LiteralSpan({required this.literal, required this.isConstant});

  String get code => "${isConstant ? 'const ' : ''}TextSpan(text: '$literal')";
}

class FunctionSpan extends BaseSpan {
  final String functionName;
  final String arg;

  FunctionSpan(this.functionName, this.arg);

  String get code => "$functionName('$arg')";
}

class VariableSpan extends BaseSpan {
  final String variableName;

  VariableSpan(this.variableName);

  @override
  String get code => '$variableName';
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
