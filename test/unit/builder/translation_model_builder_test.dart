import 'package:fast_i18n/src/builder/translation_model_builder.dart';
import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/model/context_type.dart';
import 'package:fast_i18n/src/model/node.dart';
import 'package:test/test.dart';

import '../../util/build_config_utils.dart';

void main() {
  group(TranslationModelBuilder.build, () {
    test('1 TextNode', () {
      final result = TranslationModelBuilder.build(
        buildConfig: baseConfig,
        locale: defaultLocale,
        map: {
          'test': 'a',
        },
      );
      final map = result.root.entries;
      expect((map['test'] as TextNode).content, 'a');
    });

    test('keyCase=snake and keyMapCase=camel', () {
      final result = TranslationModelBuilder.build(
        buildConfig: baseConfig.copyWith(
          maps: ['my_map'],
          keyCase: CaseStyle.snake,
          keyMapCase: CaseStyle.camel,
        ),
        locale: defaultLocale,
        map: {
          'myMap': {'my_value': 'cool'},
        },
      );
      final mapNode = result.root.entries['my_map'] as ObjectNode;
      expect((mapNode.entries['myValue'] as TextNode).content, 'cool');
    });

    test('keyCase=snake and keyMapCase=null', () {
      final result = TranslationModelBuilder.build(
        buildConfig: baseConfig.copyWith(
          maps: ['my_map'],
          keyCase: CaseStyle.snake,
        ),
        locale: defaultLocale,
        map: {
          'myMap': {'my_value 3': 'cool'},
        },
      );
      final mapNode = result.root.entries['my_map'] as ObjectNode;
      expect((mapNode.entries['my_value 3'] as TextNode).content, 'cool');
    });

    test('one link no parameters', () {
      final result = TranslationModelBuilder.build(
        buildConfig: baseConfig,
        locale: defaultLocale,
        map: {
          'a': 'A',
          'b': 'Hello @:a',
        },
      );
      final textNode = result.root.entries['b'] as TextNode;
      expect(textNode.params, <String>{});
      expect(textNode.content, r'Hello ${_root.a}');
    });

    test('one link 2 parameters straight', () {
      final result = TranslationModelBuilder.build(
        buildConfig: baseConfig,
        locale: defaultLocale,
        map: {
          'a': r'A $p1 $p1 $p2',
          'b': 'Hello @:a',
        },
      );
      final textNode = result.root.entries['b'] as TextNode;
      expect(textNode.params, {'p1', 'p2'});
      expect(textNode.content, r'Hello ${_root.a(p1: p1, p2: p2)}');
    });

    test('linked translations with parameters recursive', () {
      final result = TranslationModelBuilder.build(
        buildConfig: baseConfig,
        locale: defaultLocale,
        map: {
          'a': r'A $p1 $p1 $p2 @:b @:c',
          'b': r'Hello $p3 @:a',
          'c': r'C $p4 @:a',
        },
      );
      final textNode = result.root.entries['b'] as TextNode;
      expect(textNode.params, {'p1', 'p2', 'p3', 'p4'});
      expect(textNode.content,
          r'Hello $p3 ${_root.a(p1: p1, p2: p2, p3: p3, p4: p4)}');
    });

    test('linked translation with plural', () {
      final result = TranslationModelBuilder.build(
        buildConfig: baseConfig,
        locale: defaultLocale,
        map: {
          'a': {
            'one': 'ONE',
            'other': r'OTHER $p1',
          },
          'b': r'Hello @:a',
        },
      );
      final textNode = result.root.entries['b'] as TextNode;
      expect(textNode.params, {'p1', 'count'});
      expect(textNode.paramTypeMap, {'count': 'num'});
      expect(textNode.content, r'Hello ${_root.a(p1: p1, count: count)}');
    });

    test('linked translation with context', () {
      final result = TranslationModelBuilder.build(
        buildConfig: baseConfig.copyWith(contexts: [
          ContextType(
            enumName: 'GenderCon',
            enumValues: ['male', 'female'],
            auto: true,
            paths: [],
          ),
        ]),
        locale: defaultLocale,
        map: {
          'a': {
            'male': 'MALE',
            'female': r'FEMALE $p1',
          },
          'b': r'Hello @:a',
        },
      );
      final textNode = result.root.entries['b'] as TextNode;
      expect(textNode.params, {'p1', 'context'});
      expect(textNode.paramTypeMap, {'context': 'GenderCon'});
      expect(textNode.content, r'Hello ${_root.a(p1: p1, context: context)}');
    });
  });
}
