import 'package:slang/src/runner/main.dart' as main_runner;

/// To run this:
/// -> dart run slang
///
/// Scans translation files and builds the dart file.
/// This is usually faster than the build_runner implementation.
void main(List<String> arguments) async {
  main_runner.runFromArguments(arguments);
}
