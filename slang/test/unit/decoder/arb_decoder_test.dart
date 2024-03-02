import 'dart:convert';

import 'package:slang/src/builder/decoder/arb_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('decode', () {
    test('Should decode single string', () {
      expect(
        _decodeArb({'hello': 'world'}),
        {'hello': 'world'},
      );
    });

    test('Should decode with named parameter', () {
      expect(
        _decodeArb({'hello': 'hello {name}'}),
        {'hello': 'hello {name}'},
      );
    });

    test('Should decode with positional parameter', () {
      expect(
        _decodeArb({'hello': 'hello {0}'}),
        {'hello': 'hello {arg0}'},
      );
    });

    test('Should decode with meta', () {
      expect(
        _decodeArb({
          'hello': 'world',
          '@hello': {'description': 'This is a description'},
        }),
        {
          'hello': 'world',
          '@hello': 'This is a description',
        },
      );
    });

    test('Should decode plural string identifiers', () {
      expect(
        _decodeArb({
          'inboxCount':
              '{count, plural, zero{You have no new messages} one{You have 1 new message} other{You have {count} new messages}}'
        }),
        {
          'inboxCount(plural, param=count)': {
            'zero': 'You have no new messages',
            'one': 'You have 1 new message',
            'other': 'You have {count} new messages',
          },
        },
      );
    });

    test('Should decode plural with number identifiers', () {
      expect(
        _decodeArb({
          'inboxCount':
              '{count, plural, =0{You have no new messages} =1{You have 1 new message} other{You have {count} new messages}}'
        }),
        {
          'inboxCount(plural, param=count)': {
            'zero': 'You have no new messages',
            'one': 'You have 1 new message',
            'other': 'You have {count} new messages',
          },
        },
      );
    });

    test('Should decode custom context', () {
      expect(
        _decodeArb({
          'hello':
              '{gender, select, male{Hello Mr {name}} female{Hello Mrs {name}} other{Hello {name}}}'
        }),
        {
          'hello(context=Gender, param=gender)': {
            'male': 'Hello Mr {name}',
            'female': 'Hello Mrs {name}',
            'other': 'Hello {name}',
          },
        },
      );
    });

    test('Should decode multiple plurals', () {
      expect(
        _decodeArb({
          'inboxCount':
              '{count, plural, zero{You have no new messages} one{You have 1 new message} other{You have {count} new messages}} {appleCount, plural, zero{You have no new apples} one{You have 1 new apple} other{You have {appleCount} new apples}}'
        }),
        {
          'inboxCount__count(plural, param=count)': {
            'zero': 'You have no new messages',
            'one': 'You have 1 new message',
            'other': 'You have {count} new messages',
          },
          'inboxCount__appleCount(plural, param=appleCount)': {
            'zero': 'You have no new apples',
            'one': 'You have 1 new apple',
            'other': 'You have {appleCount} new apples',
          },
          'inboxCount': '@:inboxCount__count @:inboxCount__appleCount',
        },
      );
    });

    test('Should decode multiple plurals with same parameter', () {
      expect(
        _decodeArb({
          'inboxCount':
              '{count, plural, zero{You have no new messages} one{You have 1 new message} other{You have {count} new messages}} {count, plural, zero{You have no new apples} one{You have 1 new apple} other{You have {count} new apples}}'
        }),
        {
          'inboxCount__count(plural, param=count)': {
            'zero': 'You have no new messages',
            'one': 'You have 1 new message',
            'other': 'You have {count} new messages',
          },
          'inboxCount__count2(plural, param=count)': {
            'zero': 'You have no new apples',
            'one': 'You have 1 new apple',
            'other': 'You have {count} new apples',
          },
          'inboxCount': '@:inboxCount__count @:inboxCount__count2',
        },
      );
    });
  });
}

final _decoder = ArbDecoder();

Map<String, dynamic> _decodeArb(Map<String, dynamic> arb) {
  return _decoder.decode(jsonEncode(arb));
}
