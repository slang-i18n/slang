import 'package:slang/src/builder/builder/text/l10n_parser.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:test/test.dart';

final _locale = I18nLocale(language: 'en');

void main() {
  test('Should skip unknown type', () {
    final p = parseL10n(locale: _locale, paramName: 'p', type: 'int');
    expect(p, isNull);
  });

  test('Should parse shorthand number format', () {
    final p = parseL10n(locale: _locale, paramName: 'p', type: 'currency');
    expect(p!.paramType, 'num');
    expect(p.format, "NumberFormat.currency(locale: 'en').format(p)");
  });

  test('Should parse full number format', () {
    final p = parseL10n(
      locale: _locale,
      paramName: 'p',
      type: 'NumberFormat.currency',
    );
    expect(p!.paramType, 'num');
    expect(p.format, "NumberFormat.currency(locale: 'en').format(p)");
  });

  test('Should parse shorthand date format', () {
    final p = parseL10n(locale: _locale, paramName: 'p', type: 'yMd');
    expect(p!.paramType, 'DateTime');
    expect(p.format, "DateFormat.yMd('en').format(p)");
  });

  test('Should keep named parameter', () {
    final p = parseL10n(
      locale: _locale,
      paramName: 'p',
      type: 'NumberFormat.currency(decimalDigits: 2)',
    );
    expect(p!.paramType, 'num');
    expect(p.format,
        "NumberFormat.currency(decimalDigits: 2, locale: 'en').format(p)");
  });

  test('Should keep named string parameter', () {
    final p = parseL10n(
      locale: _locale,
      paramName: 'p',
      type: "NumberFormat.currency(symbol: '€')",
    );
    expect(p!.paramType, 'num');
    expect(
        p.format, "NumberFormat.currency(symbol: '€', locale: 'en').format(p)");
  });

  test('Should keep positional parameter', () {
    final p = parseL10n(
      locale: _locale,
      paramName: 'p',
      type: "DateFormat('yMd')",
    );
    expect(p!.paramType, 'DateTime');
    expect(p.format, "DateFormat('yMd', 'en').format(p)");
  });
}
