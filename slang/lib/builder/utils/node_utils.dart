import 'package:slang/builder/model/node.dart';

extension NodeFlatter on Node {
  /// Returns a one-dimensional map containing all nodes.
  Map<String, Node> toFlatMap() {
    final result = <String, Node>{};
    final curr = this;
    if (curr is ObjectNode && !curr.isMap) {
      // recursive
      curr.entries.values.forEach((child) {
        result.addAll(child.toFlatMap());
      });
    } else {
      result[path] = curr;
    }

    return result;
  }
}
