/// Configuration model for the "format" entry.
class FormatConfig {
  static const bool defaultEnabled = false;
  static const int? defaultWidth = null;

  final bool enabled;
  final int? width;

  const FormatConfig({
    required this.enabled,
    required this.width,
  });
}
