import 'package:slang/src/builder/model/i18n_locale.dart';
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

  group('TranslationMap.finalize', () {
    test('should be a no-op when there are no wildcard locales', () {
      final map = TranslationMap.fromMap({
        I18nLocale.fromString('en'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('de'): {
          '_default': {'hi': 'Hallo'},
        },
      });

      map.finalize();

      expect(map.getInternalMap(), {
        I18nLocale.fromString('en'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('de'): {
          '_default': {'hi': 'Hallo'},
        },
      });
    });

    test('should expand comma-separated wildcard languages', () {
      final map = TranslationMap.fromMap({
        I18nLocale.fromString('[de,en, fr]'): {
          '_default': {'hi': 'Hi'},
        },
      });

      map.finalize();

      expect(map.getInternalMap(), {
        I18nLocale.fromString('de'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('en'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('fr'): {
          '_default': {'hi': 'Hi'},
        },
      });
    });

    test('should expand wildcard languages containing country', () {
      final map = TranslationMap.fromMap({
        I18nLocale.fromString('[de,en, fr-FR]'): {
          '_default': {'hi': 'Hi'},
        },
      });

      map.finalize();

      expect(map.getInternalMap(), {
        I18nLocale.fromString('de'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('en'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('fr-FR'): {
          '_default': {'hi': 'Hi'},
        },
      });
    });

    test('should expand wildcard languages with common country', () {
      final map = TranslationMap.fromMap({
        I18nLocale.fromString('[de,en, fr]-US'): {
          '_default': {'hi': 'Hi'},
        },
      });

      map.finalize();

      expect(map.getInternalMap(), {
        I18nLocale.fromString('de-US'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('en-US'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('fr-US'): {
          '_default': {'hi': 'Hi'},
        },
      });
    });

    test('should expand comma-separated wildcard countries', () {
      final map = TranslationMap.fromMap({
        I18nLocale.fromString('en-[US,DE, FR]'): {
          '_default': {'hi': 'Hi'},
        },
      });

      map.finalize();

      expect(map.getInternalMap(), {
        I18nLocale.fromString('en-US'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('en-DE'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('en-FR'): {
          '_default': {'hi': 'Hi'},
        },
      });
    });

    test('should expand language [any]', () {
      final map = TranslationMap.fromMap({
        I18nLocale.fromString('de'): {
          '_default': {'hi': 'Hallo'},
        },
        I18nLocale.fromString('en'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('fr-FR'): {
          '_default': {'hi': 'Bonjour'},
        },
        I18nLocale.fromString('[ja-JP]'): {
          '_default': {'hi': 'Konnichiwa'},
        },
        I18nLocale.fromString('[any]-US'): {
          '_default': {'currency': 'USD'},
        },
      });

      map.finalize();

      expect(map.getInternalMap(), {
        I18nLocale.fromString('de'): {
          '_default': {'hi': 'Hallo'},
        },
        I18nLocale.fromString('en'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('fr-FR'): {
          '_default': {'hi': 'Bonjour'},
        },
        I18nLocale.fromString('ja-JP'): {
          '_default': {'hi': 'Konnichiwa'},
        },
        I18nLocale.fromString('de-US'): {
          '_default': {'currency': 'USD'},
        },
        I18nLocale.fromString('en-US'): {
          '_default': {'currency': 'USD'},
        },
        I18nLocale.fromString('fr-US'): {
          '_default': {'currency': 'USD'},
        },
        I18nLocale.fromString('ja-US'): {
          '_default': {'currency': 'USD'},
        },
      });
    });

    test('should expand country [any]', () {
      final map = TranslationMap.fromMap({
        I18nLocale.fromString('de-DE'): {
          '_default': {'hi': 'Hallo'},
        },
        I18nLocale.fromString('en-US'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('fr'): {
          '_default': {'hi': 'Bonjour'},
        },
        I18nLocale.fromString('[ja-JP]'): {
          '_default': {'hi': 'Konnichiwa'},
        },
        I18nLocale.fromString('en-[any]'): {
          '_default': {'bye': 'Bye'},
        },
      });

      map.finalize();

      expect(map.getInternalMap(), {
        I18nLocale.fromString('de-DE'): {
          '_default': {'hi': 'Hallo'},
        },
        I18nLocale.fromString('en-US'): {
          '_default': {'hi': 'Hi', 'bye': 'Bye'},
        },
        I18nLocale.fromString('fr'): {
          '_default': {'hi': 'Bonjour'},
        },
        I18nLocale.fromString('ja-JP'): {
          '_default': {'hi': 'Konnichiwa'},
        },
        I18nLocale.fromString('en-DE'): {
          '_default': {'bye': 'Bye'},
        },
        I18nLocale.fromString('en-JP'): {
          '_default': {'bye': 'Bye'},
        },
      });
    });

    test('should expand both language and country wildcards', () {
      final map = TranslationMap.fromMap({
        I18nLocale.fromString('[de,en]-[US,DE]'): {
          '_default': {'hi': 'Hi'},
        },
      });

      map.finalize();

      expect(map.getInternalMap(), {
        I18nLocale.fromString('de-US'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('de-DE'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('en-US'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('en-DE'): {
          '_default': {'hi': 'Hi'},
        },
      });
    });

    test('should expand [any]-[any]', () {
      final map = TranslationMap.fromMap({
        I18nLocale.fromString('de'): {
          '_default': {'hi': 'Hallo'},
        },
        I18nLocale.fromString('en-US'): {
          '_default': {'hi': 'Hi'},
        },
        I18nLocale.fromString('[any]-[any]'): {
          '_default': {'shared': 'yes'},
        },
      });

      map.finalize();

      expect(map.getInternalMap(), {
        I18nLocale.fromString('de'): {
          '_default': {'hi': 'Hallo'},
        },
        I18nLocale.fromString('en-US'): {
          '_default': {'hi': 'Hi', 'shared': 'yes'},
        },
        I18nLocale.fromString('de-US'): {
          '_default': {'shared': 'yes'},
        },
      });
    });

    test('should extend an existing explicit locale without overwriting', () {
      final map = TranslationMap.fromMap({
        I18nLocale.fromString('en-US'): {
          '_default': {'hi': 'original'},
        },
        I18nLocale.fromString('[de,en]-US'): {
          '_default': {'hi': 'changed', 'currency': 'EUR'},
        },
      });

      map.finalize();

      expect(map.getInternalMap(), {
        I18nLocale.fromString('en-US'): {
          '_default': {'hi': 'original', 'currency': 'EUR'},
        },
        I18nLocale.fromString('de-US'): {
          '_default': {'hi': 'changed', 'currency': 'EUR'},
        },
      });
    });
  });
}
