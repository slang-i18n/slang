import 'package:slang/src/builder/decoder/csv_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('decode', () {
    test('wrong order should throw exception', () {
      expect(
        () => CsvDecoder().decode(
          [
            'key,en,de',
            'onboarding.pages.1.title,Second Page,Zweite Seite',
            'onboarding.pages.0.title,First Page,Erste Seite',
            'onboarding.pages.0.content,First Page Content,Erster Seiteninhalt',
          ].join('\r\n'),
        ),
        throwsA(
            'The leaf "onboarding.pages.1.title" cannot be added because there are missing indices.'),
      );
    });

    test('a root entry may be a list', () {
      expect(
        CsvDecoder().decode('hello.0,hi'),
        {
          'hello': ['hi']
        },
      );
    });

    test('allow \\n', () {
      expect(
        CsvDecoder().decode('my.path,hi\nmy.path2,hello\\nworld'),
        {
          'my': {
            'path': 'hi',
            'path2': 'hello\\nworld',
          },
        },
      );
    });
  });
}
