import 'dart:convert';

import 'package:slang/runner/migrate_arb.dart';
import 'package:test/test.dart';

import '../../util/resources_utils.dart';

void main() {
  late String arbInput;
  late String expectedOutput;

  setUp(() {
    arbInput = loadResource('migration/arb.arb');
    expectedOutput = loadResource('migration/arb.json');
  });

  test('migrate arb', () {
    final result = migrateArb(arbInput, false);
    expect(JsonEncoder.withIndent('  ').convert(result), expectedOutput);
  });
}
