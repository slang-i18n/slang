import 'dart:io';

/// Formats a given directory by running a separate dart format process.
Future<void> runDartFormat({
  required String dir,
  required int? width,
}) async {
  final executable = Platform.resolvedExecutable;

  final status = Process.runSync(
    executable,
    [
      'format',
      dir,
      if (width != null) ...[
        '--line-length',
        width.toString(),
      ],
    ],
  );

  if (status.exitCode != 0) {
    print('Dart format failed with exit code ${status.exitCode}');
  }
}
