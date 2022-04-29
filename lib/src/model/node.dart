import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/context_type.dart';
import 'package:fast_i18n/src/model/interface.dart';
import 'package:fast_i18n/src/model/pluralization.dart';
import 'package:fast_i18n/src/utils/string_extensions.dart';
import 'package:fast_i18n/src/utils/regex_utils.dart';

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
    required String path,
    required String? comment,
    required String genericType,
  })  : _genericType = genericType,
        super(path: path, comment: comment);

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
    required String path,
    required String? comment,
    required this.entries,
    required this.isMap,
  }) : super(
          path: path,
          comment: comment,
          genericType: entries.values
                  .every((child) => child is StringTextNode && child.params.isEmpty)
              ? 'String'
              : 'dynamic',
        );

  void setInterface(Interface interface) {
    _interface = interface;
  }

  @override
  String toString() => entries.toString();
}

class ListNode extends IterableNode {
  final List<Node> entries;

  ListNode({
    required String path,
    required String? comment,
    required this.entries,
  }) : super(
          path: path,
          comment: comment,
          genericType: _determineGenericType(entries),
        );

  static String _determineGenericType(List<Node> entries) {
    if (entries.every((child) => child is StringTextNode && child.params.isEmpty)) {
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
    required String path,
    required String? comment,
    required this.pluralType,
    required this.quantities,
    required String? parameterName,
  })  : this.paramName = parameterName ?? 'count',
        super(path: path, comment: comment);

  @override
  String toString() => quantities.toString();
}

class ContextNode extends Node implements LeafNode {
  final ContextType context;
  final Map<String, StringTextNode> entries;
  final String paramName; // name of the context parameter

  ContextNode({
    required String path,
    required String? comment,
    required this.context,
    required this.entries,
    required String? parameterName,
  })  : this.paramName = parameterName ?? 'context',
        super(path: path, comment: comment);

  @override
  String toString() => entries.toString();
}

abstract class TextNode extends Node implements LeafNode {
  TextNode({required String path, required String? comment}) : super(path: path, comment: comment);

  String get raw;
}

class StringTextNode extends TextNode {
  /// The original string
  final String raw;

  /// Content of the text node, normalized.
  /// Will be written to .g.dart as is.
  late String _content;
  String get content => _content;

  /// Set of parameters.
  /// Hello {name}, I am {age} years old -> {'name', 'age'}
  late Set<String> _params;
  Set<String> get params => _params;

  /// Set of [TextNode] represented as path
  /// Will be used for 2nd round, determining the final set of parameters
  late Set<String> _links;
  Set<String> get links => _links;

  /// Plural and context parameters need to have a special parameter type (e.g. num)
  /// In a normal case, this parameter and its type will be added at generate stage
  ///
  /// For special cases, i.e. a translation is linked to a plural translation,
  /// the type must be specified and cannot be [Object].
  Map<String, String> _paramTypeMap = <String, String>{};
  Map<String, String> get paramTypeMap => _paramTypeMap;

  /// Several configs, persisted into node to make it easier to copy
  /// See [updateWithLinkParams]
  final StringInterpolation interpolation;
  final CaseStyle? paramCase;

  StringTextNode({
    required String path,
    required this.raw,
    required String? comment,
    required this.interpolation,
    this.paramCase,
    Map<String, Set<String>>? linkParamMap,
  }) : super(path: path, comment: comment) {
    String contentNormalized = raw
        .replaceAll('\r\n', '\\n') // (linebreak 1) -> \n
        .replaceAll('\n', '\\n') // (linebreak 2) -> \n
        .replaceAll('\'', '\\\''); // ' -> \'

    if (interpolation == StringInterpolation.dart) {
      // escape single $
      contentNormalized = contentNormalized
          .replaceAllMapped(RegexUtils.dollarOnlyRegex, (match) {
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
      contentNormalized =
          contentNormalized.replaceAllMapped(RegexUtils.dollarRegex, (match) {
        if (match.group(1) != null) {
          return '${match.group(1)}\\\$'; // with pre character
        } else {
          return '\\\$';
        }
      });
    }

    // parse arguments, modify [contentNormalized] according to interpolation
    switch (interpolation) {
      case StringInterpolation.dart:
        _params = Set<String>();
        contentNormalized = contentNormalized
            .replaceAllMapped(RegexUtils.argumentsDartRegex, (match) {
          final paramOriginal = match.group(2)!;
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
        _params = Set<String>();
        contentNormalized = contentNormalized
            .replaceAllMapped(RegexUtils.argumentsBracesRegex, (match) {
          if (match.group(1) == '\\') {
            return '{${match.group(2)}}'; // escape
          }

          final param = match.group(2)!.toCase(paramCase);
          params.add(param);

          if (match.group(3) != null) {
            // ${...} because a word follows
            return '${match.group(1)}\${$param}${match.group(3)}';
          } else {
            // $...
            return '${match.group(1)}\$$param';
          }
        });
        break;
      case StringInterpolation.doubleBraces:
        _params = Set<String>();
        contentNormalized = contentNormalized
            .replaceAllMapped(RegexUtils.argumentsDoubleBracesRegex, (match) {
          if (match.group(1) == '\\') {
            return '{{${match.group(2)}}}'; // escape
          }

          final param = match.group(2)!.toCase(paramCase);
          params.add(param);

          if (match.group(3) != null) {
            // ${...} because a word follows
            return '${match.group(1)}\${$param}${match.group(3)}';
          } else {
            // $...
            return '${match.group(1)}\$$param';
          }
        });
    }

    // detect linked translations
    this._links = Set<String>();
    this._content =
        contentNormalized.replaceAllMapped(RegexUtils.linkedRegex, (match) {
      final linkedPath = match.group(1)!;
      links.add(linkedPath);

      if (linkParamMap == null) {
        // assume no parameters
        return '\${_root.$linkedPath}';
      }

      final linkedParams = linkParamMap[linkedPath]!;
      params.addAll(linkedParams);
      final parameterString =
          linkedParams.map((param) => '$param: $param').join(', ');
      return '\${_root.$linkedPath($parameterString)}';
    });
  }

  /// Updates [content], [params] and [paramTypeMap]
  /// according to the new linked parameters
  void updateWithLinkParams({
    required Map<String, Set<String>>? linkParamMap,
    required Map<String, String> paramTypeMap,
  }) {
    this._paramTypeMap = paramTypeMap;

    // build a temporary TextNode to get the updated content and params
    final temp = StringTextNode(
      path: path,
      raw: raw,
      comment: comment,
      interpolation: interpolation,
      paramCase: paramCase,
      linkParamMap: linkParamMap,
    );

    this._params = temp.params;
    this._content = temp.content;
  }

  @override
  String toString() {
    if (params.isEmpty)
      return content;
    else
      return '$params => $content';
  }
}
