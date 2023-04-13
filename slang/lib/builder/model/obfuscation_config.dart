import 'dart:math';

final _maxInt = 256;

class ObfuscationConfig {
  static const bool defaultEnabled = false;

  final bool enabled;
  final int secret;

  ObfuscationConfig({
    required this.enabled,
    required String? secret,
  }) : secret = secret != null
            ? (secret.hashCode % _maxInt)
            : Random.secure().nextInt(_maxInt);
}
