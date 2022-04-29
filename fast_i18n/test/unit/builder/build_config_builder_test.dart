import 'package:fast_i18n/src/builder/build_config_builder.dart';
import 'package:test/test.dart';

void main() {
  group(BuildConfigBuilder.fromYaml, () {
    test('context gender default', () {
      final result = BuildConfigBuilder.fromYaml(r'''
        targets:
          $default:
            builders:
              fast_i18n:
                options:
                  input_directory: lib/i18n
                  fallback_strategy: base_locale
                  contexts:
                    GenderContext:
                      enum:
                        - male
                        - female
        ''');

      expect(result, isNotNull);
      expect(result!.contexts.length, 1);
      expect(result.contexts.first.enumName, 'GenderContext');
      expect(result.contexts.first.enumValues, ['male', 'female']);
      expect(result.contexts.first.auto, true);
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
      expect(result.contexts.first.auto, true);
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
              'auto': false,
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
      expect(result.contexts.first.auto, false);
      expect(result.contexts.first.paths, [
        'myPath',
        'mySecondPath.subPath',
      ]);
    });
  });
}
