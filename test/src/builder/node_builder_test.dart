import 'package:fast_i18n/src/builder/node_builder.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:test/test.dart';

import '../../util/build_config_utils.dart';

void main() {
  group(NodeBuilder.fromMap, () {
    test('1 TextNode', () {
      final result = NodeBuilder.fromMap(baseConfig, defaultLocale, {
        'test': 'a',
      });
      final map = result.root.entries;
      expect((map['test'] as TextNode).content, 'a');
    });

    test('keyCase=snake and keyMapCase=camel', () {
      final result = NodeBuilder.fromMap(
        baseConfig.copyWith(
          maps: ['my_map'],
          keyCase: CaseStyle.snake,
          keyMapCase: CaseStyle.camel,
        ),
        defaultLocale,
        {
          'myMap': {'my_value': 'cool'},
        },
      );
      final mapNode = result.root.entries['my_map'] as ObjectNode;
      expect((mapNode.entries['myValue'] as TextNode).content, 'cool');
    });

    test('keyCase=snake and keyMapCase=null', () {
      final result = NodeBuilder.fromMap(
        baseConfig.copyWith(
          maps: ['my_map'],
          keyCase: CaseStyle.snake,
        ),
        defaultLocale,
        {
          'myMap': {'my_value 3': 'cool'},
        },
      );
      final mapNode = result.root.entries['my_map'] as ObjectNode;
      expect((mapNode.entries['my_value 3'] as TextNode).content, 'cool');
    });
  });
}
