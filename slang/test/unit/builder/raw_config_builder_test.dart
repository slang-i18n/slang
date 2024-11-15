import 'package:slang/src/builder/builder/raw_config_builder.dart';
import 'package:slang/src/builder/model/enums.dart';
import 'package:test/test.dart';

void main() {
  group('RawConfigBuilder.fromYaml', () {
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

  group('RawConfigBuilder.fromMap', () {
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

    test('Not provided sanitization config should follow key_case', () {
      final result = RawConfigBuilder.fromMap(
        {
          'key_case': 'snake',
        },
      );

      expect(result.sanitization.caseStyle, CaseStyle.snake);
    });

    test('Not provided sanitization case should follow key_case', () {
      final result = RawConfigBuilder.fromMap(
        {
          'key_case': 'pascal',
          'sanitization': {
            'prefix': 'abc',
          },
        },
      );

      expect(result.sanitization.prefix, 'abc');
      expect(result.sanitization.caseStyle, CaseStyle.pascal);
    });

    test('Should respected sanitization case', () {
      final result = RawConfigBuilder.fromMap(
        {
          'key_case': 'snake',
          'sanitization': {
            'prefix': 'abc',
            'case': 'camel',
          },
        },
      );

      expect(result.sanitization.prefix, 'abc');
      expect(result.sanitization.caseStyle, CaseStyle.camel);
    });

    test('Should respected sanitization case of null', () {
      // Sometimes, the user explicitly wants to disable recasing.
      final result = RawConfigBuilder.fromMap(
        {
          'key_case': 'snake',
          'sanitization': {
            'prefix': 'k_',
            'case': null,
          },
        },
      );

      expect(result.sanitization.prefix, 'k_');
      expect(result.sanitization.caseStyle, isNull);
    });
  });
}
