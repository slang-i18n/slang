// ignore: implementation_imports
import 'package:slang/src/builder/utils/node_utils.dart';

const ignoreGpt = 'ignoreGpt';

/// Remove all entries from [map] that have the "ignoreMissing" modifier.
/// This method removes the entries in-place.
void removeIgnoreGpt({
  required Map<String, dynamic> map,
}) {
  final keysToRemove = <String>[];
  for (final entry in map.entries) {
    if (NodeUtils.parseModifiers(entry.key).modifiers.containsKey(ignoreGpt)) {
      keysToRemove.add(entry.key);
    } else if (entry.value is Map<String, dynamic>) {
      removeIgnoreGpt(map: entry.value);
    }
  }

  for (final key in keysToRemove) {
    map.remove(key);
  }
}

/// Remove all entries from [map] that are comments.
/// This method removes the entries in-place.
/// A new map is returned containing the comments.
Map<String, dynamic> extractComments({
  required Map<String, dynamic> map,
  required bool remove,
}) {
  final comments = <String, dynamic>{};
  final keysToRemove = <String>[];
  for (final entry in map.entries) {
    if (entry.key.startsWith('@')) {
      comments[entry.key] = entry.value;
      if (remove) {
        keysToRemove.add(entry.key);
      }
    } else if (entry.value is Map<String, dynamic>) {
      final childComments = extractComments(map: entry.value, remove: remove);
      if (childComments.isNotEmpty) {
        comments[entry.key] = childComments;
      }
      if (remove && entry.value.isEmpty) {
        keysToRemove.add(entry.key);
      }
    }
  }

  if (remove) {
    for (final key in keysToRemove) {
      map.remove(key);
    }
  }

  return comments;
}
