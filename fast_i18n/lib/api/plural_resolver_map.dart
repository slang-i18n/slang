part of 'pluralization.dart';

/// Predefined pluralization resolvers
/// See https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html
/// Sorted by language alphabetically
///
/// Contribution would be nice! (Only this file needs to be changed)
final Map<String, _Resolvers> _resolverMap = {
  // Czech
  'cs': _Resolvers(
    cardinal: (n, {zero, one, two, few, many, other}) {
      if (n == 0) {
        return zero ?? other!;
      }
      if (n == 1) {
        return one ?? other!;
      }
      if (n >= 2 && n <= 4) {
        return few ?? other!;
      }
      return other!;
    },
    ordinal: (n, {zero, one, two, few, many, other}) {
      return other!;
    },
  ),
  // German
  'de': _Resolvers(
    cardinal: (n, {zero, one, two, few, many, other}) {
      if (n == 0) {
        return zero ?? other!;
      }
      if (n == 1) {
        return one ?? other!;
      }
      return other!;
    },
    ordinal: (n, {zero, one, two, few, many, other}) {
      return other!;
    },
  ),
  // English
  'en': _Resolvers(
    cardinal: (n, {zero, one, two, few, many, other}) {
      if (n == 0) {
        return zero ?? other!;
      }
      if (n == 1) {
        return one ?? other!;
      }
      return other!;
    },
    ordinal: (n, {zero, one, two, few, many, other}) {
      if (n % 10 == 1 && n % 100 != 11) {
        return one ?? other!;
      }
      if (n % 10 == 2 && n % 100 != 12) {
        return two ?? other!;
      }
      if (n % 10 == 3 && n % 100 != 13) {
        return few ?? other!;
      }
      return other!;
    },
  ),
  // Spanish
  'es': _Resolvers(
    cardinal: (n, {zero, one, two, few, many, other}) {
      if (n == 0) {
        return zero ?? other!;
      }
      if (n == 1) {
        return one ?? other!;
      }
      return other!;
    },
    ordinal: (n, {zero, one, two, few, many, other}) {
      return other!;
    },
  ),
  // French
  'fr': _Resolvers(
    cardinal: (n, {zero, one, two, few, many, other}) {
      final i = n.toInt();
      final v = i == n ? 0 : n.toString().split('.')[1].length;
      if (n == 0) {
        return zero ?? one ?? other!;
      }
      if (i == 1) {
        return one ?? other!;
      }
      if (i != 0 && i % 1000000 == 0 && v == 0) {
        return many ?? other!;
      }
      return other!;
    },
    ordinal: (n, {zero, one, two, few, many, other}) {
      if (n == 1) {
        return many ?? other!;
      }
      return other!;
    },
  ),
  // Italian
  'it': _Resolvers(
    cardinal: (n, {zero, one, two, few, many, other}) {
      final i = n.toInt();
      final v = i == n ? 0 : n.toString().split('.')[1].length;
      if (n == 0) {
        return zero ?? other!;
      }
      if (i == 1 && v == 0) {
        return one ?? other!;
      }
      return other!;
    },
    ordinal: (n, {zero, one, two, few, many, other}) {
      if (n == 8 || n == 11 || n == 80 || n == 800) {
        return many ?? other!;
      }
      return other!;
    },
  ),
  // Swedish
  'sv': _Resolvers(
    cardinal: (n, {zero, one, two, few, many, other}) {
      if (n == 0) {
        return zero ?? other!;
      }
      if (n == 1) {
        return one ?? other!;
      }
      return other!;
    },
    ordinal: (n, {zero, one, two, few, many, other}) {
      if (n % 10 == 1 && n % 100 != 11) {
        return one ?? other!;
      }
      if (n % 10 == 2 && n % 100 != 12) {
        return one ?? other!;
      }
      return other!;
    },
  ),
  // Vietnamese
  'vi': _Resolvers(
    cardinal: (n, {zero, one, two, few, many, other}) {
      if (n == 0) {
        return zero ?? other!;
      }
      return other!;
    },
    ordinal: (n, {zero, one, two, few, many, other}) {
      if (n == 1) {
        return one ?? other!;
      }
      return other!;
    },
  ),
};
