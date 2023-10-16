import 'package:slang/src/runner/migrate_arb.dart';

Future<void> runMigrate(List<String> arguments) async {
  if (arguments.length != 3) {
    throw 'Migrate must have 3 arguments: <type> <source> <destination>';
  }

  switch (arguments[0]) {
    case 'arb':
      await migrateArbRunner(
        sourcePath: arguments[1],
        destinationPath: arguments[2],
      );
      break;
    default:
      throw 'Unknown migration type: ${arguments[0]}';
  }
}
