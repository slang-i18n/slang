import 'package:fast_i18n/src/model/node.dart';
import 'package:fast_i18n/src/parser/json_parser.dart';
import 'package:test/test.dart';

import '../../util/build_config_utils.dart';

void main() {
  group(JsonParser.parseTranslations, () {
    test('one text', () {
      final root = JsonParser.parseTranslations(baseConfig, defaultLocale, '''{
        "hi": "hello"
      }''').root;
      expect(root.entries.length, 1);
      expect(root.entries.entries.first.key, 'hi');
      expect(root.entries.entries.first.value, isA<TextNode>());
      expect((root.entries.entries.first.value as TextNode).content, 'hello');
      expect((root.entries.entries.first.value as TextNode).params, []);
    });

    test('root map', () {
      final config = baseConfig.copyWith(maps: ['myMap']);
      final root = JsonParser.parseTranslations(config, defaultLocale, '''{
        "hi": "hello",
        "myMap": {
          "a": "a"
        }
      }''').root;
      expect(root.entries.length, 2);
      expect(root.entries.entries.first.value, isA<TextNode>());
      expect(root.entries.entries.last.value, isA<ObjectNode>());
      expect(root.entries.entries.last.key, 'myMap');
      expect((root.entries.entries.last.value as ObjectNode).type,
          ObjectNodeType.map);
      expect(
          (root.entries.entries.last.value as ObjectNode).plainStrings, true);
    });

    test('root list', () {
      final root = JsonParser.parseTranslations(baseConfig, defaultLocale, '''{
        "hi": "hello",
        "myList": [
          "a"
        ]
      }''').root;
      expect(root.entries.length, 2);
      expect(root.entries.entries.first.value, isA<TextNode>());
      expect(root.entries.entries.last.value, isA<ListNode>());
      expect((root.entries.entries.last.value as ListNode).entries.length, 1);
      expect((root.entries.entries.last.value as ListNode).plainStrings, true);
    });

    test('numbers', () {
      final root = JsonParser.parseTranslations(baseConfig, defaultLocale, '''{
        "a": 1,
        "myList": [
          2.2
        ],
        "myMap": {
          "myKey": 3
        }
      }''').root;
      final map = root.entries;
      expect(map.entries.length, 3);
      expect(map['a'], isA<TextNode>());
      expect((map['a'] as TextNode).content, '1');
      expect(map['myList'], isA<ListNode>());
      expect(
          ((map['myList'] as ListNode).entries[0] as TextNode).content, '2.2');
      expect(map['myMap'], isA<ObjectNode>());
    });
  });
}
