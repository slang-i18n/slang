import 'package:fast_i18n/src/model/pluralization.dart';

/// Predefined pluralization resolvers
/// See https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html
/// - sorted by language alphabetically
/// - the parameter name is "n"
///
/// Contribution would be nice!
const List<PluralizationResolver> PLURALIZATION_RESOLVERS = [
  PluralizationResolver(
      language: 'cs',
      cardinal: RuleSet(rules: [
        Rule('n == 1', Quantity.one),
        Rule('n >= 2 && n <= 4', Quantity.few)
      ], defaultQuantity: Quantity.other),
      ordinal: RuleSet(rules: [], defaultQuantity: Quantity.other)),
  PluralizationResolver(
      language: 'de',
      cardinal: RuleSet(
          rules: [Rule('n == 1', Quantity.one)],
          defaultQuantity: Quantity.other),
      ordinal: RuleSet(rules: [], defaultQuantity: Quantity.other)),
  PluralizationResolver(
      language: 'en',
      cardinal: RuleSet(
          rules: [Rule('n == 1', Quantity.one)],
          defaultQuantity: Quantity.other),
      ordinal: RuleSet(rules: [
        Rule('n % 10 == 1 && n % 100 != 11', Quantity.one),
        Rule('n % 10 == 2 && n % 100 != 12', Quantity.two),
        Rule('n % 10 == 3 && n % 100 != 13', Quantity.few),
      ], defaultQuantity: Quantity.other)),
  PluralizationResolver(
    language: 'vi',
    cardinal: RuleSet(rules: [], defaultQuantity: Quantity.other),
    ordinal: RuleSet(
        rules: [Rule('n == 1', Quantity.one)], defaultQuantity: Quantity.other),
  )
];
