import 'dart:io';

void main() async {
  print(
      '\n-> Running alias for "flutter pub run build_runner build --delete-conflicting-outputs"\n');
  var process = await Process.start('flutter',
      ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      runInShell: true);
  process.stdout.pipe(stdout);
}
