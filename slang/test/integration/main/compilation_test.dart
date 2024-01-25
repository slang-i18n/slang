import 'package:expect_error/expect_error.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

/// These tests ensure that the generated code compiles.
void main() {
  late Library library;

  setUp(() async {
    // A workaround so we have Flutter available in the analyzer.
    // See: https://pub.dev/packages/expect_error#flutter-support
    library = await Library.custom(
      packageName: 'slang_flutter',
      path: 'not used',
      packageRoot: '../slang_flutter',
    );
  });

  Future<void> expectCompiles(String path) {
    final output = loadResource(path);
    return expectLater(library.withCode(output), compiles);
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

  test('single output', () {
    expectCompiles('main/_expected_single.output');
  });

  test('translation overrides', () {
    expectCompiles('main/_expected_translation_overrides.output');
  });
}
