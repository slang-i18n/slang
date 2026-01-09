import 'package:slang/src/builder/builder/build_model_config_builder.dart';
import 'package:slang/src/builder/builder/translation_model_builder.dart';
import 'package:slang/src/builder/model/context_type.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/interface.dart';
import 'package:slang/src/builder/model/node.dart';
import 'package:slang/src/builder/model/raw_config.dart';
import 'package:test/test.dart';

final _locale = I18nLocale(language: 'en');

void main() {
  test('1 StringTextNode', () {
    final result = TranslationModelBuilder.build(
      buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
      locale: _locale,
      map: {
        'test': 'a',
      },
    );
    final map = result.root.entries;
    expect((map['test'] as StringTextNode).content, 'a');
  });

  group('ObjectNode', () {
    test('Should not generate empty ObjectNodes', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
        locale: _locale,
        map: {
          'empty': <String, dynamic>{},
          'nestedEmpty': {
            'empty': <String, dynamic>{},
          },
        },
      );
      expect(result.root.entries, isEmpty);
    });
  });

  group('Recasing', () {
    test('keyCase=snake and keyMapCase=camel', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.copyWith(
          maps: ['my_map'],
          keyCase: CaseStyle.snake,
          keyMapCase: CaseStyle.camel,
        ).toBuildModelConfig(),
        locale: _locale,
        map: {
          'myMap': {'my_value': 'cool'},
        },
      );
      final mapNode = result.root.entries['my_map'] as ObjectNode;
      expect((mapNode.entries['myValue'] as StringTextNode).content, 'cool');
    });

    test('keyCase=snake and keyMapCase=null', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.copyWith(
          maps: ['my_map'],
          keyCase: CaseStyle.snake,
        ).toBuildModelConfig(),
        locale: _locale,
        map: {
          'myMap': {'my_value 3': 'cool'},
        },
      );
      final mapNode = result.root.entries['my_map'] as ObjectNode;
      expect((mapNode.entries['my_value 3'] as StringTextNode).content, 'cool');
    });
  });

  group('Linked Translations', () {
    test('one link no parameters', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
        locale: _locale,
        map: {
          'a': 'A',
          'b': 'Hello @:a',
        },
      );
      final textNode = result.root.entries['b'] as StringTextNode;
      expect(textNode.params, <String>{});
      expect(textNode.content, r'Hello ${_root.a}');
    });

    test('should keep non-link parameter type', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
        locale: _locale,
        map: {
          'a': r'A $p2',
          'b': r'Hello ${p1: bool} @:a',
        },
      );
      final textNode = result.root.entries['b'] as StringTextNode;
      expect(textNode.params, {'p1', 'p2'});
      expect(textNode.content, r'Hello ${p1} ${_root.a(p2: p2)}');
      expect(textNode.paramTypeMap, {'p1': 'bool', 'p2': 'Object'});
    });

    test('one link 2 parameters straight', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
        locale: _locale,
        map: {
          'a': r'A $p1 $p1 $p2',
          'b': 'Hello @:a',
        },
      );
      final textNode = result.root.entries['b'] as StringTextNode;
      expect(textNode.params, {'p1', 'p2'});
      expect(textNode.content, r'Hello ${_root.a(p1: p1, p2: p2)}');
    });

    test('linked translations with parameters recursive', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
        locale: _locale,
        map: {
          'a': r'A $p1 $p1 $p2 @:b @:c',
          'b': r'Hello $p3 @:a',
          'c': r'C $p4 @:a',
        },
      );
      final textNode = result.root.entries['b'] as StringTextNode;
      expect(textNode.params, {'p1', 'p2', 'p3', 'p4'});
      expect(textNode.content,
          r'Hello ${p3} ${_root.a(p1: p1, p2: p2, p3: p3, p4: p4)}');
    });

    test('linked translation with plural', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
        locale: _locale,
        map: {
          'a': {
            'one': 'ONE',
            'other': r'OTHER ${p1: String}',
          },
          'b': r'Hello @:a',
        },
      );
      final textNode = result.root.entries['b'] as StringTextNode;
      expect(textNode.params, {'p1', 'n'});
      expect(textNode.paramTypeMap, {'n': 'num', 'p1': 'String'});
      expect(textNode.content, r'Hello ${_root.a(p1: p1, n: n)}');
    });

    test('linked translation with plural and custom number type', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
        locale: _locale,
        map: {
          'a': {
            'one': 'ONE',
            'other': r'OTHER ${n: int} ${p1: String}',
          },
          'b': r'Hello @:a',
        },
      );
      final textNode = result.root.entries['b'] as StringTextNode;
      expect(textNode.params, {'p1', 'n'});
      expect(textNode.paramTypeMap, {'n': 'int', 'p1': 'String'});
      expect(textNode.content, r'Hello ${_root.a(n: n, p1: p1)}');
    });

    test('linked translation with context', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.copyWith(contexts: [
          ContextType(
            enumName: 'GenderCon',
            defaultParameter: 'gender',
            generateEnum: true,
          ),
        ]).toBuildModelConfig(),
        locale: _locale,
        map: {
          'a(context=GenderCon)': {
            'male': 'MALE',
            'female': r'FEMALE $p1',
          },
          'b': r'Hello @:a',
        },
      );
      final textNode = result.root.entries['b'] as StringTextNode;
      expect(textNode.params, {'p1', 'gender'});
      expect(textNode.paramTypeMap, {'p1': 'Object', 'gender': 'GenderCon'});
      expect(textNode.content, r'Hello ${_root.a(p1: p1, gender: gender)}');
    });
  });

  group('Context Type', () {
    test('Should not include context type if values are unspecified', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.copyWith(contexts: [
          ContextType(
            enumName: 'GenderCon',
            defaultParameter: 'gender',
            generateEnum: true,
          ),
        ]).toBuildModelConfig(),
        locale: _locale,
        map: {
          'a': 'b',
        },
      );

      expect(result.contexts, []);
    });
  });

  group('Interface', () {
    test('empty lists should take generic type of interface', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.copyWith(interfaces: [
          InterfaceConfig(
            name: 'MyInterface',
            paths: [InterfacePath('myEntry')],
            attributes: {
              InterfaceAttribute(
                attributeName: 'myList',
                returnType: 'List<MyType>',
                parameters: {},
                optional: false,
              )
            },
          ),
          InterfaceConfig(
            name: 'MyInterface2',
            paths: [InterfacePath('myEntry2.*')],
            attributes: {
              InterfaceAttribute(
                attributeName: 'myList',
                returnType: 'List<MyType2>',
                parameters: {},
                optional: false,
              )
            },
          ),
        ]).toBuildModelConfig(),
        locale: _locale,
        map: {
          'myEntry': {
            'myList': [],
          },
          'myEntry2': {
            'child': {
              'myList': [],
            },
          },
        },
      );

      final objectNode = result.root.entries['myEntry'] as ObjectNode;
      expect((objectNode.entries['myList'] as ListNode).genericType, 'MyType');

      final objectNode2 = (result.root.entries['myEntry2'] as ObjectNode)
          .entries['child'] as ObjectNode;
      expect(
          (objectNode2.entries['myList'] as ListNode).genericType, 'MyType2');
    });

    test('Should handle nested interfaces specified via modifier', () {
      final resultUsingModifiers = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
        map: {
          'myContainer(interface=MyInterface)': {
            'firstItem': {
              'a': 'A1',
              'nestedItem(singleInterface=MyNestedInterface)': {
                'z': 'Z',
              },
            },
            'secondItem': {
              'a': 'A2',
              'nestedItem(singleInterface=MyNestedInterface)': {
                'z': 'Z',
              },
            },
            'thirdItem': {
              'a': 'A3',
              'nestedItem(singleInterface=MyNestedInterface)': {
                'z': 'Z',
              },
            },
          }
        },
        locale: _locale,
      );

      _checkInterfaceResult(resultUsingModifiers);
    });

    test('Should handle nested interface specified via config', () {
      final resultUsingConfig = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.copyWith(
          interfaces: [
            InterfaceConfig(
              name: 'MyNestedInterface',
              paths: [],
              attributes: {
                InterfaceAttribute(
                  attributeName: 'z',
                  returnType: 'String',
                  parameters: {},
                  optional: false,
                ),
              },
            ),
          ],
        ).toBuildModelConfig(),
        map: {
          'myContainer(interface=MyInterface)': {
            'firstItem': {
              'a': 'A1',
              'nestedItem': {
                'z': 'Z',
              },
            },
            'secondItem': {
              'a': 'A2',
              'nestedItem': {
                'z': 'Z',
              },
            },
            'thirdItem': {
              'a': 'A3',
              'nestedItem': {
                'z': 'Z',
              },
            },
          }
        },
        locale: _locale,
      );

      _checkInterfaceResult(resultUsingConfig);
    });
  });

  group('Sanitization', () {
    test('Should sanitize reserved keyword', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
        locale: _locale,
        map: {
          'continue': 'Continue',
        },
      );

      expect(result.root.entries['continue'], isNull);
      expect(result.root.entries['kContinue'], isA<StringTextNode>());
    });

    test('Should not sanitize keys in maps', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
        locale: _locale,
        map: {
          'a(map)': {
            'continue': 'Continue',
          },
        },
      );

      final mapNode = result.root.entries['a'] as ObjectNode;
      expect(mapNode.entries['continue'], isA<StringTextNode>());
      expect(mapNode.entries['kContinue'], isNull);
    });

    test('Should add quotations for keys with special characters in maps', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig.toBuildModelConfig(),
        locale: _locale,
        map: {
          'a(map)': {
            '3': 'is a number',
            'has.dots': 'has dots',
          },
        },
      );

      final mapNode = result.root.entries['a'] as ObjectNode;
      expect(mapNode.entries.length, 2);
      expect(mapNode.entries['"3"'], isA<StringTextNode>());
      expect(mapNode.entries['3'], isNull);
      expect(mapNode.entries['"has.dots"'], isA<StringTextNode>());
      expect(mapNode.entries['has.dots'], isNull);
    });
  });

  group('Fallback', () {
    test('base_locale_empty_string: Do not remove empty strings in base locale',
        () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig
            .copyWith(
              fallbackStrategy: FallbackStrategy.baseLocaleEmptyString,
            )
            .toBuildModelConfig(),
        locale: _locale,
        map: {'hello': ''},
      );

      expect(result.root.entries['hello'], isA<StringTextNode>());
      expect((result.root.entries['hello'] as StringTextNode).content, '');
    });

    test('Should fallback context type cases', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig
            .copyWith(
              fallbackStrategy: FallbackStrategy.baseLocale,
            )
            .toBuildModelConfig(),
        locale: _locale,
        map: {
          'hello(context=GenderCon)': {
            'a': 'A',
            'c': 'C',
          }
        },
        baseData: TranslationModelBuilder.build(
          buildConfig: RawConfig.defaultConfig.copyWith(
            contexts: [
              ContextType(
                enumName: 'GenderCon',
                defaultParameter: 'default',
                generateEnum: true,
              ),
            ],
          ).toBuildModelConfig(),
          locale: _locale,
          map: {
            'hello(context=GenderCon)': {
              'a': 'Base A',
              'b': 'Base B',
              'c': 'Base C',
            },
          },
        ),
      );

      final textNode = result.root.entries['hello'] as ContextNode;
      expect(textNode.entries.length, 3);
      expect(
        textNode.entries.values.map((e) => (e as StringTextNode).content),
        [
          'A',
          'Base B',
          'C',
        ],
      );
    });

    test('Should not fallback map entry by default', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig
            .copyWith(
              fallbackStrategy: FallbackStrategy.baseLocale,
            )
            .toBuildModelConfig(),
        locale: _locale,
        map: {
          'myMap(map)': {
            'a': 'A',
            'c': 'C',
          }
        },
        baseData: TranslationModelBuilder.build(
          buildConfig: RawConfig.defaultConfig.copyWith().toBuildModelConfig(),
          locale: _locale,
          map: {
            'myMap(map)': {
              'a': 'Base A',
              'b': 'Base B',
              'c': 'Base C',
            },
          },
        ),
      );

      final textNode = result.root.entries['myMap'] as ObjectNode;
      expect(textNode.entries.length, 2);
      expect(
        textNode.entries.values.map((e) => (e as StringTextNode).content),
        [
          'A',
          'C',
        ],
      );
    });

    test('Should fallback map entry when fallback modifier is added', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig
            .copyWith(
              fallbackStrategy: FallbackStrategy.baseLocale,
            )
            .toBuildModelConfig(),
        locale: _locale,
        map: {
          'myMap(map, fallback)': {
            'a': 'A',
            'c': 'C',
          }
        },
        baseData: TranslationModelBuilder.build(
          buildConfig: RawConfig.defaultConfig.copyWith().toBuildModelConfig(),
          locale: _locale,
          map: {
            'myMap(map, fallback)': {
              'a': 'Base A',
              'b': 'Base B',
              'c': 'Base C',
            },
          },
        ),
      );

      final textNode = result.root.entries['myMap'] as ObjectNode;
      expect(textNode.entries.length, 3);
      expect(
        textNode.entries.values.map((e) => (e as StringTextNode).content),
        [
          'A',
          'Base B',
          'C',
        ],
      );
    });

    test('Should respect base_locale_empty_string in fallback map', () {
      final result = TranslationModelBuilder.build(
        buildConfig: RawConfig.defaultConfig
            .copyWith(
              fallbackStrategy: FallbackStrategy.baseLocaleEmptyString,
            )
            .toBuildModelConfig(),
        locale: _locale,
        map: {
          'myMap(map, fallback)': {
            'a': 'A',
            'c': '',
          }
        },
        baseData: TranslationModelBuilder.build(
          buildConfig: RawConfig.defaultConfig.copyWith().toBuildModelConfig(),
          locale: _locale,
          map: {
            'myMap(map, fallback)': {
              'a': 'Base A',
              'b': 'Base B',
              'c': 'Base C',
            },
          },
        ),
      );

      final textNode = result.root.entries['myMap'] as ObjectNode;
      expect(textNode.entries.length, 3);
      expect(
        textNode.entries.values.map((e) => (e as StringTextNode).content),
        [
          'A',
          'Base B',
          'Base C',
        ],
      );
    });
  });
}

void _checkInterfaceResult(BuildModelResult result) {
  final interfaces = result.interfaces;
  expect(interfaces.length, 2);
  expect(interfaces[0].name, 'MyNestedInterface');
  expect(interfaces[0].attributes.length, 1);
  expect(interfaces[0].attributes.first.attributeName, 'z');
  expect(interfaces[1].name, 'MyInterface');
  expect(interfaces[1].attributes.length, 2);
  expect(interfaces[1].attributes.first.attributeName, 'a');
  expect(interfaces[1].attributes.last.attributeName, 'nestedItem');

  final objectNode = result.root.entries['myContainer'] as ObjectNode;
  expect(objectNode.interface, isNull);

  expect(objectNode.entries['firstItem'], isA<ObjectNode>());
  expect(objectNode.entries['secondItem'], isA<ObjectNode>());
  expect(objectNode.entries['thirdItem'], isA<ObjectNode>());

  expect((objectNode.entries['firstItem'] as ObjectNode).interface?.name,
      'MyInterface');
  expect((objectNode.entries['secondItem'] as ObjectNode).interface?.name,
      'MyInterface');
  expect((objectNode.entries['thirdItem'] as ObjectNode).interface?.name,
      'MyInterface');

  expect(
      ((objectNode.entries['firstItem'] as ObjectNode).entries['nestedItem']
              as ObjectNode)
          .interface
          ?.name,
      'MyNestedInterface');
  expect(
      ((objectNode.entries['secondItem'] as ObjectNode).entries['nestedItem']
              as ObjectNode)
          .interface
          ?.name,
      'MyNestedInterface');
  expect(
      ((objectNode.entries['thirdItem'] as ObjectNode).entries['nestedItem']
              as ObjectNode)
          .interface
          ?.name,
      'MyNestedInterface');
}
