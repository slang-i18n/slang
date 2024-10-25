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

  test('Should keep locale in named arguments', () {
    final p = parseL10n(
      locale: _locale,
      paramName: 'p',
      type: "NumberFormat.currency(symbol: '€', locale: 'de')",
    );
    expect(p!.paramType, 'num');
    expect(
        p.format, "NumberFormat.currency(symbol: '€', locale: 'de').format(p)");
  });

  test('Should keep locale in positional arguments', () {
    final p = parseL10n(
      locale: _locale,
      paramName: 'p',
      type: "NumberFormat('###', 'fr')",
    );
    expect(p!.paramType, 'num');
    expect(p.format, "NumberFormat('###', 'fr').format(p)");
  });

  test('Should keep locale in single positional argument', () {
    final p = parseL10n(
      locale: _locale,
      paramName: 'p',
      type: "yMd('fr')",
    );
    expect(p!.paramType, 'DateTime');
    expect(p.format, "DateFormat.yMd('fr').format(p)");
  });

  test('Should add locale even if there is a comma (false positive)', () {
    final p = parseL10n(
      locale: _locale,
      paramName: 'p',
      type: "NumberFormat('###,###')",
    );
    expect(p!.paramType, 'num');
    expect(p.format, "NumberFormat('###,###', 'en').format(p)");
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
