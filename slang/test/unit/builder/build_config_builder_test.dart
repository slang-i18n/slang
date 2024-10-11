import 'package:slang/src/builder/builder/raw_config_builder.dart';
import 'package:test/test.dart';

void main() {
  group(RawConfigBuilder.fromYaml, () {
    test('context gender default', () {
      final result = RawConfigBuilder.fromYaml(r'''
        targets:
          $default:
            builders:
              slang_build_runner:
                options:
                  input_directory: lib/i18n
                  fallback_strategy: base_locale
                  contexts:
                    GenderContext:
                      default_parameter: gender
                      render_enum: false
        ''');

      expect(result, isNotNull);
      expect(result!.contexts.length, 1);
      expect(result.contexts.first.enumName, 'GenderContext');
      expect(result.contexts.first.defaultParameter, 'gender');
    });
  });

  group(RawConfigBuilder.fromMap, () {
    test('context gender default', () {
      final result = RawConfigBuilder.fromMap(
        {
          'contexts': {
            'GenderContext': {
              'enum': [
                'male',
                'female',
                'neutral',
              ],
            },
          },
        },
      );

      expect(result.contexts.length, 1);
      expect(result.contexts.first.enumName, 'GenderContext');
      expect(result.contexts.first.defaultParameter, 'context');
    });

    test('Should remove trailing slash', () {
      final result = RawConfigBuilder.fromMap(
        {
          'input_directory': 'lib/abc/',
        },
      );

      expect(result.inputDirectory, 'lib/abc');
    });
  });
}
