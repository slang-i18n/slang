class PluralizationResolver {
  final RuleSet cardinal;
  final RuleSet ordinal;

  const PluralizationResolver({required this.cardinal, required this.ordinal});
}

class RuleSet {
  /// Generate a i variable. 'i' is a integer digits of n.
  final bool i;

  /// Generate a v variable. 'v' is a number of visible fraction digits in n.
  final bool v;

  final List<Rule> rules;
  final Quantity defaultQuantity;

  RuleSet({
    this.i = false,
    this.v = false,
    List<Rule>? rules,
    required this.defaultQuantity,
  }) : rules = rules ?? [];
}

class Rule {
  final String condition;
  final Quantity result;

  const Rule(this.condition, this.result);
}

enum Quantity { zero, one, two, few, many, other }

extension QuantityExtensions on Quantity {
  String paramName() {
    switch (this) {
      case Quantity.zero:
        return 'zero';
      case Quantity.one:
        return 'one';
      case Quantity.two:
        return 'two';
      case Quantity.few:
        return 'few';
      case Quantity.many:
        return 'many';
      case Quantity.other:
        return 'other';
    }
  }
}
