import 'package:slang/api/secret.dart';
import 'package:slang/src/builder/utils/encryption_utils.dart';
import 'package:test/test.dart';

void main() {
  group('calc0', () {
    test('214', () {
      const secret = 214;
      final parts = getParts0(secret);
      expect($calc0(parts[0], parts[1], parts[2]), secret);
    });
    test('-9', () {
      const secret = -9;
      final parts = getParts0(secret);
      expect($calc0(parts[0], parts[1], parts[2]), secret);
    });
  });

  group('calc1', () {
    test('214', () {
      const secret = 214;
      final parts = getParts1(secret);
      expect($calc1(parts[0], parts[1], parts[2]), secret);
    });
    test('-9', () {
      const secret = -9;
      final parts = getParts1(secret);
      expect($calc1(parts[0], parts[1], parts[2]), secret);
    });
  });
}
