import 'package:slang/src/utils/log.dart' as log;

void printHelp() {
  log.info('''
Slang: Type-safe i18n for Dart and Flutter.

Main command:
  dart run slang - Generates the Dart code.
  dart run slang watch - Generates the Dart code and watches for changes.

Tools:
  dart run slang configure                                         - Update configuration files.
  dart run slang analyze [--split] [--full] [--outdir=assets/i18n] - Analyze translations.
  dart run slang clean [--outdir=assets/i18n]                      - Remove unused translations (requires analyze).
  dart run slang apply [--locale=fr-FR] [--outdir=assets/i18n]     - Add new translations (requires analyze).
  dart run slang edit <type> <params...>                           - Edit translations.
  dart run slang normalize [--locale=fr-FR]                        - Normalize translations.
  dart run slang outdated <key>                                    - Flag translation as outdated.
  dart run slang migrate <type> <source> <destination>             - Migrate translations.
  dart run slang stats                                             - Show translation statistics.

For more information, visit
  https://pub.dev/packages/slang
''');
}
