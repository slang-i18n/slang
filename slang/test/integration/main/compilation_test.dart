import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

/// These tests ensure that the generated code compiles.
/// It currently only checks for syntax errors.
void main() {
  void expectCompiles(String path) {
    final output = loadResource(path);
    final result = parseString(
      path: 'path.dart',
      content: output,
    );
    expect(result.errors, isEmpty);
  }

  test('fallback base locale', () {
    expectCompiles('main/_expected_fallback_base_locale.output');
  });

  test('no flutter', () {
    expectCompiles('main/_expected_no_flutter.output');
  });

  test('obfuscation', () {
    expectCompiles('main/_expected_obfuscation.output');
  });

  test('rich text', () {
    expectCompiles('main/_expected_rich_text.output');
  });

  test('translation overrides', () {
    expectCompiles('main/_expected_translation_overrides.output');
  });
}
