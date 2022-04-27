class BaseAppLocale {
  final String languageCode;
  final String? scriptCode;
  final String? countryCode;

  const BaseAppLocale({
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
  });
}
