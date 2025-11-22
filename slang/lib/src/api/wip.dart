class WipStrings {
  const WipStrings._();

  static const instance = WipStrings._();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod && invocation.positionalArguments.length == 1) {
      return invocation.positionalArguments[0];
    }
    if (invocation.isGetter) {
      return WipStrings.instance;
    }
    return super.noSuchMethod(invocation);
  }
}
