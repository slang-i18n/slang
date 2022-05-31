import 'package:slang/builder/builder/build_config_builder.dart';
import 'package:test/test.dart';

void main() {
  group(BuildConfigBuilder.fromYaml, () {
    test('context gender default', () {
      final result = BuildConfigBuilder.fromYaml(r'''
        targets:
          $default:
            builders:
              slang_build_runner:
                options:
                  input_directory: lib/i18n
                  fallback_strategy: base_locale
                  contexts:
                    GenderContext:
                      enum:
                        - male
                        - female
                      default_parameter: gender
                      render_enum: false
        ''');

      expect(result, isNotNull);
      expect(result!.contexts.length, 1);
      expect(result.contexts.first.enumName, 'GenderContext');
      expect(result.contexts.first.enumValues, ['male', 'female']);
      expect(result.contexts.first.defaultParameter, 'gender');
      expect(result.contexts.first.paths, []);
    });
  });

  group(BuildConfigBuilder.fromMap, () {
    test('context gender default', () {
      final result = BuildConfigBuilder.fromMap(
        {
          'contexts': {
            'gender_context': {
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
      expect(result.contexts.first.enumValues, ['male', 'female', 'neutral']);
      expect(result.contexts.first.defaultParameter, 'context');
      expect(result.contexts.first.paths, []);
    });

    test('context gender with path', () {
      final result = BuildConfigBuilder.fromMap(
        {
          'contexts': {
            'gender_context': {
              'enum': [
                'male',
                'female',
              ],
              'paths': [
                'myPath',
                'mySecondPath.subPath',
              ],
            },
          },
        },
      );

      expect(result.contexts.length, 1);
      expect(result.contexts.first.enumName, 'GenderContext');
      expect(result.contexts.first.enumValues, ['male', 'female']);
      expect(result.contexts.first.defaultParameter, 'context');
      expect(result.contexts.first.paths, [
        'myPath',
        'mySecondPath.subPath',
      ]);
    });
  });
}
