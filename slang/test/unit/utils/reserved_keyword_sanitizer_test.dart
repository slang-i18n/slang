import 'package:slang/src/builder/model/enums.dart';
import 'package:slang/src/builder/utils/reserved_keyword_sanitizer.dart';
import 'package:test/test.dart';

String _sanitizeDefault(String name) => sanitizeReservedKeyword(
      name: name,
      prefix: 'k_',
      sanitizeCaseStyle: CaseStyle.camel,
      defaultCaseStyle: CaseStyle.camel,
    );

void main() {
  test('Should sanitize keywords', () {
    expect(_sanitizeDefault('continue'), 'kContinue');
  });

  test('Should not sanitize non-keywords', () {
    expect(_sanitizeDefault('hello'), 'hello');
  });

  test('Should sanitize keywords with numbers', () {
    expect(_sanitizeDefault('1continue'), 'k1continue');
  });

  test('Should not recase', () {
    expect(
      sanitizeReservedKeyword(
        name: 'continue',
        prefix: 'k',
        sanitizeCaseStyle: null,
        defaultCaseStyle: CaseStyle.camel,
      ),
      'kcontinue',
    );
  });

  test('Should recase correctly', () {
    expect(
      sanitizeReservedKeyword(
        name: 'continue',
        prefix: 'k',
        sanitizeCaseStyle: CaseStyle.snake,
        defaultCaseStyle: CaseStyle.camel,
      ),
      'k_continue',
    );
  });
}
