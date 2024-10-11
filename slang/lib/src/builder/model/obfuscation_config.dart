import 'dart:math';

final _maxInt = 256;

class ObfuscationConfig {
  static const bool defaultEnabled = false;

  final bool enabled;
  final int secret;

  const ObfuscationConfig._({
    required this.enabled,
    required this.secret,
  });

  factory ObfuscationConfig.disabled() => const ObfuscationConfig._(
        enabled: false,
        secret: 0,
      );

  factory ObfuscationConfig.fromSecretString({
    required bool enabled,
    required String? secret,
  }) =>
      ObfuscationConfig._(
        enabled: enabled,
        secret: secret != null
            ? (secret.hashCode % _maxInt)
            : Random.secure().nextInt(_maxInt),
      );

  factory ObfuscationConfig.fromSecretInt({
    required bool enabled,
    required int secret,
  }) =>
      ObfuscationConfig._(
        enabled: enabled,
        secret: secret,
      );
}
