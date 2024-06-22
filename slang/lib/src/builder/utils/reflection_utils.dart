/// Returns a list of function parameters of a given [function].
/// Expects the function to contain either no parameters or
/// only required named parameters.
Set<String> getFunctionParameters(Function function) {
  // e.g. ({required num count, required Object name}) => String
  final typeString = function.runtimeType.toString();

  if (typeString.startsWith('() =>')) {
    return const {};
  }

  final parameterList = typeString.substring(
      typeString.indexOf('({') + 1, typeString.indexOf('})'));
  return parameterList.split(',').map((e) => e.split(' ').last).toSet();
}
