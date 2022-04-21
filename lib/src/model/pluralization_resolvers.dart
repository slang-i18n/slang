import 'package:fast_i18n/src/model/pluralization.dart';

/// Predefined pluralization resolvers
/// See https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html
/// - sorted by language alphabetically
/// - the parameter name is "n"
///
/// Contribution would be nice!
// ignore: non_constant_identifier_names
final Map<String, PluralizationResolver> PLURALIZATION_RESOLVERS = {
  // Czech
  'cs:': PluralizationResolver(
    cardinal: RuleSet(
      rules: [
        Rule('n == 0', Quantity.zero),
        Rule('n == 1', Quantity.one),
        Rule('n >= 2 && n <= 4', Quantity.few),
      ],
      defaultQuantity: Quantity.other,
    ),
    ordinal: RuleSet(defaultQuantity: Quantity.other),
  ),
  // German
  'de': PluralizationResolver(
    cardinal: RuleSet(
      rules: [
        Rule('n == 0', Quantity.zero),
        Rule('n == 1', Quantity.one),
      ],
      defaultQuantity: Quantity.other,
    ),
    ordinal: RuleSet(defaultQuantity: Quantity.other),
  ),
  // English
  'en': PluralizationResolver(
    cardinal: RuleSet(
      rules: [
        Rule('n == 0', Quantity.zero),
        Rule('n == 1', Quantity.one),
      ],
      defaultQuantity: Quantity.other,
    ),
    ordinal: RuleSet(
      rules: [
        Rule('n % 10 == 1 && n % 100 != 11', Quantity.one),
        Rule('n % 10 == 2 && n % 100 != 12', Quantity.two),
        Rule('n % 10 == 3 && n % 100 != 13', Quantity.few),
      ],
      defaultQuantity: Quantity.other,
    ),
  ),
  // Spanish
  'es': PluralizationResolver(
    cardinal: RuleSet(
      rules: [
        Rule('n == 1', Quantity.one),
      ],
      defaultQuantity: Quantity.other,
    ),
    ordinal: RuleSet(
      defaultQuantity: Quantity.other,
    ),
  ),
  // French
  'fr': PluralizationResolver(
    cardinal: RuleSet(
      i: true,
      v: true,
      rules: [
        Rule('i == 0 || i == 1', Quantity.one),
        Rule('i != 0 && i % 1000000 == 0 && v == 0', Quantity.many),
      ],
      defaultQuantity: Quantity.other,
    ),
    ordinal: RuleSet(
      rules: [
        Rule('n == 1', Quantity.many),
      ],
      defaultQuantity: Quantity.other,
    ),
  ),
  // Italian
  'it': PluralizationResolver(
    cardinal: RuleSet(
      i: true,
      v: true,
      rules: [
        Rule('i == 1 && v == 0', Quantity.one),
      ],
      defaultQuantity: Quantity.other,
    ),
    ordinal: RuleSet(
      rules: [
        Rule('n == 8 || n == 11 || n == 80 || n == 800', Quantity.many),
      ],
      defaultQuantity: Quantity.other,
    ),
  ),
  // Swedish
  'sv': PluralizationResolver(
    cardinal: RuleSet(
      rules: [
        const Rule('n == 0', Quantity.zero),
        const Rule('n == 1', Quantity.one),
      ],
      defaultQuantity: Quantity.other,
    ),
    ordinal: RuleSet(
      rules: [
        const Rule("n % 10 == 1 && n % 100 != 11", Quantity.one),
        const Rule("n % 10 == 2 && n % 100 != 12", Quantity.one),
      ],
      defaultQuantity: Quantity.other,
    ),
  ),
  // Vietnamese
  'vi': PluralizationResolver(
    cardinal: RuleSet(
      rules: [
        Rule('n == 0', Quantity.zero),
      ],
      defaultQuantity: Quantity.other,
    ),
    ordinal: RuleSet(
      rules: [
        Rule('n == 1', Quantity.one),
      ],
      defaultQuantity: Quantity.other,
    ),
  )
};
