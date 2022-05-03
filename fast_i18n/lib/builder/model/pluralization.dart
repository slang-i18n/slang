class PluralizationResolver {
  final RuleSet cardinal;
  final RuleSet ordinal;

  const PluralizationResolver({required this.cardinal, required this.ordinal});
}

class RuleSet {
  /// Generate variable 'i', integer of 'n'.
  final bool i;

  /// Generate variable 'v', visible fraction digits of n.
  final bool v;

  /// List of rules representing 'if' statements. Order matters!
  final List<Rule> rules;

  /// The quantity if all rules failed or no rules are defined.
  final Quantity defaultQuantity;

  RuleSet({
    this.i = false,
    this.v = false,
    List<Rule>? rules,
    required this.defaultQuantity,
  }) : rules = rules ?? [];
}

class Rule {
  /// The if-condition, rendered as is.
  final String condition;

  /// The resulting quantity if [condition] is true
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

extension QuantityParser on String {
  Quantity? toQuantity() {
    switch (this) {
      case 'zero':
        return Quantity.zero;
      case 'one':
        return Quantity.one;
      case 'two':
        return Quantity.two;
      case 'few':
        return Quantity.few;
      case 'many':
        return Quantity.many;
      case 'other':
        return Quantity.other;
      default:
        return null;
    }
  }
}
