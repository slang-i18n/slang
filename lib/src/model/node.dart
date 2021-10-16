import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/context_type.dart';
import 'package:fast_i18n/src/string_extensions.dart';
import 'package:fast_i18n/src/utils.dart';

/// the super class of every node
abstract class Node {
  static const KEY_DELIMITER = ','; // used by context
}

enum ObjectNodeType {
  classType, // represent this object as class
  map, // as Map<String,dynamic>
  pluralCardinal, // as function
  pluralOrdinal, // as function
  context, // as function
}

class ObjectNode extends Node {
  final Map<String, Node> entries;
  final ObjectNodeType type;
  final bool plainStrings;
  final ContextType? contextHint; // to save computing power by calc only once

  ObjectNode(this.entries, this.type, this.contextHint)
      : plainStrings = entries.values
            .every((child) => child is TextNode && child.params.isEmpty);

  @override
  String toString() => entries.toString();
}

class ListNode extends Node {
  final List<Node> entries;
  final bool plainStrings;

  ListNode(this.entries)
      : plainStrings =
            entries.every((child) => child is TextNode && child.params.isEmpty);

  @override
  String toString() => entries.toString();
}

class TextNode extends Node {
  /// The original string
  late final String raw;

  /// Content of the text node, normalized.
  /// Will be written to .g.dart as is.
  late String content;

  /// Set of parameters.
  /// Hello {name}, I am {age} years old -> {'name', 'age'}
  late Set<String> params;

  /// Set of [TextNode] represented as path
  /// Will be used for 2nd round, determining the final set of parameters
  late final Set<String> links;

  /// Plural and context parameters need to have a special parameter type (e.g. num)
  /// In a normal case, this parameter and its type will be added at generate stage
  ///
  /// For special cases, i.e. a translation is linked to a plural translation,
  /// the type must be specified and cannot be [Object].
  Map<String, String> paramTypeMap = <String, String>{};

  TextNode(
    String content,
    StringInterpolation interpolation,
    String localeEnum, [
    CaseStyle? paramCase,
    Map<String, Set<String>>? linkParamMap,
  ]) {
    raw = content;

    String contentNormalized = content
        .replaceAll('\r\n', '\\n') // (linebreak 1) -> \n
        .replaceAll('\n', '\\n') // (linebreak 2) -> \n
        .replaceAll('\'', '\\\''); // ' -> \'

    if (interpolation == StringInterpolation.dart) {
      // escape single $
      contentNormalized =
          contentNormalized.replaceAllMapped(Utils.dollarOnlyRegex, (match) {
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
          contentNormalized.replaceAllMapped(Utils.dollarRegex, (match) {
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
        params = Set<String>();
        contentNormalized = contentNormalized
            .replaceAllMapped(Utils.argumentsDartRegex, (match) {
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
        params = Set<String>();
        contentNormalized = contentNormalized
            .replaceAllMapped(Utils.argumentsBracesRegex, (match) {
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
        params = Set<String>();
        contentNormalized = contentNormalized
            .replaceAllMapped(Utils.argumentsDoubleBracesRegex, (match) {
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
    this.links = Set<String>();
    this.content =
        contentNormalized.replaceAllMapped(Utils.linkedRegex, (match) {
      final linkedPath = match.group(1)!;
      links.add(linkedPath);

      if (linkParamMap == null) {
        // assume no parameters
        return '\${$localeEnum.translations.$linkedPath}';
      }

      final linkedParams = linkParamMap[linkedPath]!;
      params.addAll(linkedParams);
      final parameterString =
          linkedParams.map((param) => '$param: $param').join(', ');
      return '\${$localeEnum.translations.$linkedPath($parameterString)}';
    });
  }

  @override
  String toString() {
    if (params.isEmpty)
      return content;
    else
      return '$params => $content';
  }
}
