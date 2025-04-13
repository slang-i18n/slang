import 'package:slang/src/builder/utils/yaml_writer.dart';
import 'package:test/test.dart';

void main() {
  group('convertToYaml', () {
    test('should convert empty map', () {
      expect(convertToYaml({}), equals(''));
    });

    test('should convert simple key-value pairs', () {
      final input = {
        'name': 'John',
        'age': 30,
        'isActive': true,
        'height': 1.85,
        'nullable': null
      };
      final expected = '''name: John
age: 30
isActive: true
height: 1.85
nullable: null
''';
      expect(convertToYaml(input), equals(expected));
    });

    test('should convert nested maps', () {
      final input = {
        'person': {
          'name': 'Alice',
          'details': {'age': 28, 'job': 'Engineer'}
        }
      };
      final expected = '''person: 
  name: Alice
  details: 
    age: 28
    job: Engineer
''';
      expect(convertToYaml(input), equals(expected));
    });

    test('should properly quote strings with special characters', () {
      final input = {
        'special': {
          'empty': '',
          'with_question': '? a',
          'with:colon': 'inner spaces',
          'with_spaces': r'  padded  "\ ',
          'with_at': '@username',
          'with_ampersand': '&reference',
          'empty_map': '{}',
          'empty_list': '[]',
          'json_like': '{"name": "value"}',
          'array_like': '[1, 2, 3]',
          'normal': 'normal'
        }
      };
      final expected = r'''special: 
  empty: ""
  with_question: "? a"
  "with:colon": inner spaces
  with_spaces: "  padded  \"\\ "
  with_at: "@username"
  with_ampersand: "&reference"
  empty_map: "{}"
  empty_list: "[]"
  json_like: "{\"name\": \"value\"}"
  array_like: "[1, 2, 3]"
  normal: normal
''';
      expect(convertToYaml(input), equals(expected));
    });

    test('should format multiline strings with pipe notation', () {
      final input = {
        'without_nl': 'This is a\nmultiline string\n with several lines',
        'with_nl': 'This is a\nmultiline string\n with newline\n',
      };
      final expected = '''without_nl: |-
  This is a
  multiline string
   with several lines
with_nl: |
  This is a
  multiline string
   with newline
''';
      expect(convertToYaml(input), equals(expected));
    });

    test('should convert lists', () {
      final input = {
        'fruits': ['apple', 'banana', 'cherry'],
      };
      final expected = '''fruits: 
  - apple
  - banana
  - cherry
''';
      expect(convertToYaml(input), equals(expected));
    });

    test('should convert lists of maps', () {
      final input = {
        'contacts': [
          {'type': 'email', 'value': 'john@example.com'},
          {'type': 'phone', 'value': '555-1234'}
        ]
      };
      final expected = '''contacts: 
  - 
    type: email
    value: john@example.com
  - 
    type: phone
    value: 555-1234
''';
      expect(convertToYaml(input), equals(expected));
    });

    test('should handle complex nested structures', () {
      final input = {
        'company': {
          'name': 'Acme Inc',
          'departments': [
            {
              'name': 'Engineering',
              'employees': [
                {'name': 'Bob', 'role': 'Developer'},
                {'name': 'Alice', 'role': 'Architect'}
              ]
            },
            {
              'name': 'Marketing',
              'employees': [
                {'name': 'Charlie', 'role': 'Manager'}
              ]
            }
          ]
        }
      };
      final expected = '''company: 
  name: Acme Inc
  departments: 
    - 
      name: Engineering
      employees: 
        - 
          name: Bob
          role: Developer
        - 
          name: Alice
          role: Architect
    - 
      name: Marketing
      employees: 
        - 
          name: Charlie
          role: Manager
''';
      expect(convertToYaml(input), equals(expected));
    });

    test('should handle nested lists', () {
      final input = {
        'matrix': [
          [1, 2, 3],
          [4, 5, 6]
        ]
      };
      final expected = '''matrix: 
  - 
    - 1
    - 2
    - 3
  - 
    - 4
    - 5
    - 6
''';
      expect(convertToYaml(input), equals(expected));
    });
  });
}
