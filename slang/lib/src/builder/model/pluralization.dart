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
