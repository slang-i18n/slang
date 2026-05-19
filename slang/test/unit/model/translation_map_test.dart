import 'package:slang/src/builder/model/translation_map.dart';
import 'package:test/test.dart';

void main() {
  group('FlatNamespaceMap.expand', () {
    test('should return as-is when no dots and no default namespace', () {
      final flat = FlatNamespaceMap({
        'widgets': {
          'title': 'My Widget',
        },
      });

      final result = flat.expand();

      expect(result, {
        'widgets': {
          'title': 'My Widget',
        },
      });
    });

    test('should expand dot-separated keys into nested maps', () {
      final flat = FlatNamespaceMap({
        'widgets': {
          'title': 'My Widget',
        },
        'widgets.buttons': {
          'ok': 'OK',
          'cancel': 'Cancel',
        },
      });

      final result = flat.expand();

      expect(result, {
        'widgets': {
          'title': 'My Widget',
          'buttons': {
            'ok': 'OK',
            'cancel': 'Cancel',
          },
        },
      });
    });

    test('should merge default namespace to top level', () {
      final flat = FlatNamespaceMap({
        '_default': {
          'hello': 'Hello',
          'bye': 'Bye',
        },
        'widgets': {
          'title': 'My Widget',
        },
      });

      final result = flat.expand();

      expect(result, {
        'hello': 'Hello',
        'bye': 'Bye',
        'widgets': {
          'title': 'My Widget',
        },
      });
    });

    test('should handle both dot expansion and default namespace', () {
      final flat = FlatNamespaceMap({
        '_default': {
          'hello': 'Hello',
        },
        'widgets': {
          'title': 'My Widget',
        },
        'widgets.buttons': {
          'ok': 'OK',
        },
      });

      final result = flat.expand();

      expect(result, {
        'hello': 'Hello',
        'widgets': {
          'title': 'My Widget',
          'buttons': {
            'ok': 'OK',
          },
        },
      });
    });

    test('namespace values should override default namespace on conflict', () {
      final flat = FlatNamespaceMap({
        '_default': {
          'widgets': 'should be overridden',
        },
        'widgets': {
          'title': 'My Widget',
        },
      });

      final result = flat.expand();

      expect(result['widgets'], {
        'title': 'My Widget',
      });
    });
  });

  group('ExpandedNamespaceMap.flatten', () {
    test('should collect non-namespace keys into default namespace', () {
      final expanded = ExpandedNamespaceMap({
        'hello': 'Hello',
        'bye': 'Bye',
        'widgets': {
          'title': 'My Widget',
        },
      });

      final result = expanded.flatten(namespaces: {'widgets'});

      expect(result, {
        '_default': {
          'hello': 'Hello',
          'bye': 'Bye',
        },
        'widgets': {
          'title': 'My Widget',
        },
      });
    });

    test('should flatten nested namespaces to dot-separated keys', () {
      final expanded = ExpandedNamespaceMap({
        'widgets': {
          'title': 'My Widget',
          'buttons': {
            'ok': 'OK',
            'cancel': 'Cancel',
          },
        },
      });

      final result = expanded.flatten(namespaces: {
        'widgets',
        'widgets.buttons',
      });

      expect(result, {
        'widgets': {
          'title': 'My Widget',
        },
        'widgets.buttons': {
          'ok': 'OK',
          'cancel': 'Cancel',
        },
      });
    });

    test('should return only default namespace when no namespaces', () {
      final expanded = ExpandedNamespaceMap({
        'hello': 'Hello',
        'bye': 'Bye',
      });

      final result = expanded.flatten(namespaces: {});

      expect(result, {
        '_default': {
          'hello': 'Hello',
          'bye': 'Bye',
        },
      });
    });

    test('should handle empty map', () {
      final expanded = ExpandedNamespaceMap({});

      final result = expanded.flatten(namespaces: {});

      expect(result, <String, Map<String, dynamic>>{});
    });

    test('should handle namespace not present in map', () {
      final expanded = ExpandedNamespaceMap({
        'hello': 'Hello',
      });

      final result = expanded.flatten(namespaces: {'widgets'});

      expect(result, {
        '_default': {
          'hello': 'Hello',
        },
      });
    });
  });

  group('digest and flatten roundtrip', () {
    test('should roundtrip with default namespace and namespaces', () {
      final original = FlatNamespaceMap({
        '_default': {
          'hello': 'Hello',
          'bye': 'Bye',
        },
        'widgets': {
          'title': 'My Widget',
        },
        'widgets.buttons': {
          'ok': 'OK',
          'cancel': 'Cancel',
        },
      });

      final digested = original.expand();
      final flattened = digested.flatten(namespaces: {
        'widgets',
        'widgets.buttons',
      });

      expect(flattened, original);
    });
  });
}
