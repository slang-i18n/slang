import 'package:slang/builder/model/obfuscation_config.dart';
import 'package:slang/src/builder/generator/helper.dart';
import 'package:test/test.dart';

void main() {
  group('getStringLiteral', () {
    test('Should return text as is', () {
      final config = ObfuscationConfig.disabled();
      expect(getStringLiteral('Hello World', config), "'Hello World'");
    });

    test('Should obfuscate word with zero XOR', () {
      final config = ObfuscationConfig.fromSecretInt(
        enabled: true,
        secret: 0,
      );
      expect(getStringLiteral('abc', config), '_root.\$meta.d([97, 98, 99])');
    });

    test('Should obfuscate word with positive XOR', () {
      final config = ObfuscationConfig.fromSecretInt(
        enabled: true,
        secret: 1,
      );
      expect(getStringLiteral('abc', config), '_root.\$meta.d([96, 99, 98])');
      expect(_d([96, 99, 98], 1), 'abc');
    });

    test('Should obfuscate with escaped line break', () {
      final config = ObfuscationConfig.fromSecretInt(
        enabled: true,
        secret: 1,
      );
      expect(getStringLiteral('a\\nb', config), '_root.\$meta.d([96, 11, 99])');
      expect(_d([96, 11, 99], 1), 'a\nb');
    });

    test('Should obfuscate with escaped single tick', () {
      final config = ObfuscationConfig.fromSecretInt(
        enabled: true,
        secret: 1,
      );
      expect(getStringLiteral("a\\'b", config), '_root.\$meta.d([96, 38, 99])');
      expect(_d([96, 38, 99], 1), "a'b");
    });
  });
}

String _d(List<int> chars, int secret) {
  for (int i = 0; i < chars.length; i++) {
    chars[i] = chars[i] ^ secret;
  }
  return String.fromCharCodes(chars);
}
