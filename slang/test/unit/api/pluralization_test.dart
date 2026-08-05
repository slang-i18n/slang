import 'package:slang/slang.dart';
import 'package:test/test.dart';

void main() {
  group('Hebrew plural resolver', () {
    final cardinal = PluralResolvers.cardinal('he');
    final ordinal = PluralResolvers.ordinal('he');

    String resolveCardinal(num n) => cardinal(
          n,
          one: 'one',
          two: 'two',
          other: 'other',
        );

    String resolveOrdinal(num n) => ordinal(
          n,
          one: 'one',
          two: 'two',
          other: 'other',
        );

    test('selects cardinal forms according to CLDR', () {
      expect(resolveCardinal(0), 'other');
      expect(resolveCardinal(0.5), 'one');
      expect(resolveCardinal(1), 'one');
      expect(resolveCardinal(1.5), 'other');
      expect(resolveCardinal(2), 'two');
      expect(resolveCardinal(2.5), 'other');
      expect(resolveCardinal(3), 'other');
      expect(resolveCardinal(10), 'other');
    });

    test('allows Hebrew translations to omit the number for one and two', () {
      String minutes(num n) => cardinal(
            n,
            one: 'דקה',
            two: 'שתי דקות',
            other: '$n דקות',
          );
      String days(num n) => cardinal(
            n,
            one: 'יום',
            two: 'יומיים',
            other: '$n ימים',
          );

      expect(minutes(1), 'דקה');
      expect(minutes(2), 'שתי דקות');
      expect(minutes(3), '3 דקות');
      expect(days(1), 'יום');
      expect(days(2), 'יומיים');
      expect(days(3), '3 ימים');
    });

    test('always selects other for ordinals', () {
      for (final n in [0, 1, 2, 3, 10, 21]) {
        expect(resolveOrdinal(n), 'other');
      }
    });
  });
}
