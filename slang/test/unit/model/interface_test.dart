import 'package:slang/builder/model/interface.dart';
import 'package:test/test.dart';

Interface _i(Map<String, bool> attributes, [String name = '']) {
  return Interface(
    name: name,
    attributes: {
      for (final a in attributes.entries) _attr(a.key, a.value),
    },
  );
}

InterfaceAttribute _attr(String name, [bool optional = false]) {
  return InterfaceAttribute(
    attributeName: name,
    returnType: '',
    parameters: {},
    optional: optional,
  );
}

void main() {
  group('Interface.extend', () {
    test('extend with itself should not change', () {
      final i0 = _i({'a': false});
      expect(i0.extend(i0.attributes), i0);
    });

    test('new parameters should be optional if not exist in old', () {
      final i0 = _i({'a': false});
      final i1 = _i({'a': false, 'b': false});
      final e = _i({'a': false, 'b': true});
      expect(i0.extend(i1.attributes), e);
    });

    test('new parameters should be optional if old is optional', () {
      final i0 = _i({'a': false, 'b': true});
      final i1 = _i({'a': false, 'b': false});
      final e = _i({'a': false, 'b': true});
      expect(i0.extend(i1.attributes), e);
    });

    test('optional parameters should stay optional', () {
      final i0 = _i({'a': false, 'b': true, 'c': true});
      final i1 = _i({'a': true, 'b': false, 'c': true});
      final e = _i({'a': true, 'b': true, 'c': true});
      expect(i0.extend(i1.attributes), e);
    });

    test('no common', () {
      final i0 = _i({'a': false, 'b': false});
      final i1 = _i({'c': false, 'd': false});
      final e = _i({'a': true, 'b': true, 'c': true, 'd': true});
      expect(i0.extend(i1.attributes), e);
    });

    test('only optional', () {
      final i0 = _i({'a': true, 'b': true});
      final i1 = _i({'c': true, 'd': true});
      final e = _i({'a': true, 'b': true, 'c': true, 'd': true});
      expect(i0.extend(i1.attributes), e);
    });
  });
}
