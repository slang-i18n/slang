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
      cardinal: RuleSet(rules: [
        Rule('n == 0', Quantity.zero),
        Rule('n == 1', Quantity.one),
        Rule('n >= 2 && n <= 4', Quantity.few),
      ], defaultQuantity: Quantity.other),
      ordinal: RuleSet(defaultQuantity: Quantity.other)),
  // German
  'de': PluralizationResolver(
      cardinal: RuleSet(rules: [
        Rule('n == 0', Quantity.zero),
        Rule('n == 1', Quantity.one),
      ], defaultQuantity: Quantity.other),
      ordinal: RuleSet(defaultQuantity: Quantity.other)),
  // English
  'en': PluralizationResolver(
      cardinal: RuleSet(rules: [
        Rule('n == 0', Quantity.zero),
        Rule('n == 1', Quantity.one),
      ], defaultQuantity: Quantity.other),
      ordinal: RuleSet(rules: [
        Rule('n % 10 == 1 && n % 100 != 11', Quantity.one),
        Rule('n % 10 == 2 && n % 100 != 12', Quantity.two),
        Rule('n % 10 == 3 && n % 100 != 13', Quantity.few),
      ], defaultQuantity: Quantity.other)),
  // Vietnamese
  'vi': PluralizationResolver(
    cardinal: RuleSet(
      rules: [
        Rule('n == 0', Quantity.zero),
      ],
      defaultQuantity: Quantity.other,
    ),
    ordinal: RuleSet(
        rules: [Rule('n == 1', Quantity.one)], defaultQuantity: Quantity.other),
  )
};
