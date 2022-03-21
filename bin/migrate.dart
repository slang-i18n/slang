import 'package:fast_i18n/src/tools/migrate_arb.dart';

void main(List<String> arguments) async {
  if (arguments.length != 3) {
    throw 'Migrate must have 3 arguments: <type> <source> <destination>';
  }

  switch (arguments[0]) {
    case 'arb':
      migrateArbRunner(arguments[1], arguments[2]);
      break;
    default:
      throw 'Unknown migration type: ${arguments[0]}';
  }
}
