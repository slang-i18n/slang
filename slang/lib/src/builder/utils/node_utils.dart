import 'package:slang/builder/model/node.dart';
import 'package:slang/src/builder/utils/regex_utils.dart';

class NodeUtils {
  /// Returns a map containing modifiers
  /// greet(param=gender, rich)
  /// will result in
  /// {param: gender, rich: rich}
  static NodePathInfo parseModifiers(String originalKey) {
    final match = RegexUtils.modifierRegex.firstMatch(originalKey);
    if (match == null) {
      return NodePathInfo(path: originalKey, modifiers: {});
    }

    final modifiers = match.group(2)!.split(',');
    final resultMap = <String, String>{};
    for (final modifier in modifiers) {
      if (modifier.contains('=')) {
        final parts = modifier.split('=');
        if (parts.length != 2) {
          throw 'Hints must be in format "key: value" or "key"';
        }

        resultMap[parts[0].trim()] = parts[1].trim();
      } else {
        final modifierDigested = modifier.trim();
        resultMap[modifierDigested] = modifierDigested;
      }
    }
    return NodePathInfo(
      path: match.group(1)!,
      modifiers: resultMap,
    );
  }

  /// Takes a [modifiers] map and returns the string representation.
  static String serializeModifiers(String key, Map<String, String> modifiers) {
    if (modifiers.isEmpty) {
      return key;
    }

    final modifierList = modifiers.entries.map((entry) {
      if (entry.key == entry.value) {
        return entry.key;
      } else {
        return '${entry.key}=${entry.value}';
      }
    }).toList();

    return '$key(${modifierList.join(', ')})';
  }

  /// Adds a modifier to the [original] key.
  static String addModifier({
    required String original,
    required String modifierKey,
    String? modifierValue,
  }) {
    final info = parseModifiers(original);
    return serializeModifiers(
      info.path,
      {
        ...info.modifiers,
        modifierKey: modifierValue ?? modifierKey,
      },
    );
  }
}

class NodePathInfo {
  final String path;
  final Map<String, String> modifiers;

  const NodePathInfo({
    required this.path,
    required this.modifiers,
  });
}

extension StringModifierExt on String {
  /// Returns the key without modifiers.
  String get withoutModifiers {
    final index = indexOf('(');
    if (index == -1) {
      return this;
    }
    return substring(0, index);
  }

  String withModifier(String modifierKey, [String? modifierValue]) {
    return NodeUtils.addModifier(
      original: this,
      modifierKey: modifierKey,
      modifierValue: modifierValue,
    );
  }
}

extension NodeFlatter on Node {
  /// Returns a one-dimensional map containing all nodes.
  Map<String, Node> toFlatMap() {
    final result = <String, Node>{};
    final curr = this;
    if (curr is ObjectNode && !curr.isMap) {
      // recursive
      for (final child in curr.entries.values) {
        result.addAll(child.toFlatMap());
      }
    } else {
      result[path] = curr;
    }

    return result;
  }
}
