/// Configuration model for the "autodoc" entry.
class AutodocConfig {
  static const bool defaultEnabled = true;
  static const List<String> defaultLocales = [base];
  static const String base = r'$BASE$';

  final bool enabled;
  final List<String> locales;

  const AutodocConfig({
    required this.enabled,
    required this.locales,
  });
}
