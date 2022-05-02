/// Similar to the [Locale] class of Flutter
/// But without any Flutter dependencies
class AppLocaleId {
  final String languageCode;
  final String? scriptCode;
  final String? countryCode;

  static const AppLocaleId UNDEFINED_LANGUAGE = AppLocaleId(
    languageCode: 'und',
  );

  const AppLocaleId({
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
  });

  String get languageTag => [languageCode, scriptCode, countryCode]
      .where((element) => element != null)
      .join('-');

  @override
  String toString() =>
      'AppLocaleId{languageCode: $languageCode, scriptCode: $scriptCode, countryCode: $countryCode}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLocaleId &&
          runtimeType == other.runtimeType &&
          languageCode == other.languageCode &&
          scriptCode == other.scriptCode &&
          countryCode == other.countryCode;

  @override
  int get hashCode =>
      languageCode.hashCode ^ scriptCode.hashCode ^ countryCode.hashCode;
}
