import 'package:fast_i18n/src/parser/yaml_parser.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group(YamlParser.deepCast, () {
    test('one text', () {
      final input = '''
      my key: my value
      ''';
      final parsed = loadYaml(input);
      final casted = YamlParser.deepCast(parsed);
      expect(casted, {'my key': 'my value'});
      expect(casted['my key'], isA<String>());
    });

    test('one list', () {
      final input = '''
      my key:
        - a
        - b
        - 3
      ''';
      final parsed = loadYaml(input);
      final casted = YamlParser.deepCast(parsed);
      expect(casted, {
        'my key': ['a', 'b', 3]
      });
      expect(casted['my key'], isA<List>());
    });

    test('one map', () {
      final input = '''
      my key:
        cool: a
        3: 2
      ''';
      final parsed = loadYaml(input);
      final casted = YamlParser.deepCast(parsed);
      expect(casted, {
        'my key': {
          'cool': 'a',
          '3': 2,
        },
      });
      expect(casted['my key'], isA<Map<String, dynamic>>());
    });

    test('nested', () {
      final input = '''
      my master key:
        - cool: a
          3: 2
        - 4: 5
          nested list:
            - first item
            - second item
            - first map item: 1
              2: 2
      ''';
      final parsed = loadYaml(input);
      final casted = YamlParser.deepCast(parsed);
      expect(casted, {
        'my master key': [
          {
            'cool': 'a',
            '3': 2,
          },
          {
            '4': 5,
            'nested list': [
              'first item',
              'second item',
              {
                'first map item': 1,
                '2': 2,
              }
            ],
          },
        ],
      });
      expect(casted['my master key'], isA<List<dynamic>>());
      expect(casted['my master key'][0], isA<Map<String, dynamic>>());
      expect(casted['my master key'][1], isA<Map<String, dynamic>>());
      expect(casted['my master key'][1]['nested list'][2],
          isA<Map<String, dynamic>>());
    });
  });
}
