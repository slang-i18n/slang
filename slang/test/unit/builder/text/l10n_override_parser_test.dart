import 'package:intl/date_symbol_data_local.dart';
import 'package:slang/src/builder/builder/text/l10n_override_parser.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    initializeDateFormatting();
  });

  test('Should skip unknown type', () {
    final p = digestL10nOverride(
      existingTypes: {},
      locale: 'en',
      type: 'lol',
      value: 33,
    );
    expect(p, isNull);
  });

  test('Should parse shorthand number format', () {
    final p = digestL10nOverride(
      existingTypes: {},
      locale: 'en',
      type: 'currency',
      value: 33,
    );
    expect(p!, r'USD33.00');
  });

  test('Should parse full number format', () {
    final p = digestL10nOverride(
      existingTypes: {},
      locale: 'en',
      type: 'NumberFormat.currency',
      value: 33,
    );
    expect(p!, r'USD33.00');
  });

  test('Should parse custom number format', () {
    final p = digestL10nOverride(
      existingTypes: {},
      locale: 'en',
      type: 'NumberFormat("000.00")',
      value: 33,
    );
    expect(p!, r'033.00');
  });

  test('Should parse number format with parameters', () {
    final p = digestL10nOverride(
      existingTypes: {},
      locale: 'en',
      type: 'NumberFormat.currency(decimalDigits: 3, symbol: "€")',
      value: 33,
    );
    expect(p!, r'€33.000');
  });

  test('Should parse shorthand date format', () {
    final p = digestL10nOverride(
      existingTypes: {},
      locale: 'en',
      type: 'yMd',
      value: DateTime(2021, 12, 31),
    );
    expect(p!, '12/31/2021');
  });

  test('Should parse custom date format', () {
    final p = digestL10nOverride(
      existingTypes: {},
      locale: 'en',
      type: 'DateFormat("yyyy-MM-dd")',
      value: DateTime(2021, 12, 31),
    );
    expect(p!, '2021-12-31');
  });

  test('Should keep locale in positional argument', () {
    final p = digestL10nOverride(
      existingTypes: {},
      locale: 'en',
      type: 'NumberFormat("000.00", "de")',
      value: 33.4,
    );
    expect(p!, '033,40');
  });

  test('Should keep locale in single positional argument', () {
    final p = digestL10nOverride(
      existingTypes: {},
      locale: 'en',
      type: 'yMd("de")',
      value: DateTime(2021, 12, 31),
    );
    expect(p!, '31.12.2021');
  });

  test('Should keep locale in named argument', () {
    final p = digestL10nOverride(
      existingTypes: {},
      locale: 'en',
      type: 'currency(symbol: "€", locale: "de")',
      value: 33.4,
    );
    expect(p!, '33,40 €');
  });
}
