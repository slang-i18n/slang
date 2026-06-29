import 'dart:io';

/// Release script for slang.
///
/// Usage: fvm dart run release.dart
///
/// Steps:
///  1. Validate that slang, slang_flutter and slang_build_runner share the same
///     version and that slang_flutter / slang_build_runner declare the correct
///     constraint on slang.
///  2. Temporarily point `origin` at GitHub, push the new tag, then restore the
///     Codeberg remote.
const _githubRemote = 'git@github.com:slang-i18n/slang.git';
const _codebergRemote = 'ssh://git@codeberg.org/Tienisto/slang.git';

void main() {
  // 1. Validate versions and constraints.
  final version = _readVersion('slang/pubspec.yaml');
  print('detected slang version: $version');

  final expectedConstraint = _expectedConstraint(version);
  print('expected slang constraint: $expectedConstraint');

  for (final pkg in ['slang_flutter', 'slang_build_runner']) {
    final pkgVersion = _readVersion('$pkg/pubspec.yaml');
    if (pkgVersion != version) {
      throw '$pkg version is $pkgVersion but expected $version';
    }

    final constraint = _readSlangConstraint('$pkg/pubspec.yaml');
    if (constraint != expectedConstraint) {
      throw '$pkg has slang constraint "$constraint" but expected "$expectedConstraint"';
    }
  }

  print('All versions and constraints are valid.');

  final tag = 'v$version';

  // 2. Point origin at GitHub, push the tag, then restore Codeberg.
  _setOrigin(_githubRemote);
  try {
    _git(['tag', tag]);
    _git(['push', 'origin', 'main']);
    _git(['push', 'origin', tag]);
    print('Pushed $tag to GitHub.');
  } finally {
    _setOrigin(_codebergRemote);
  }
  print('Done.');
}

final _versionRegex = RegExp(
  r'^version: (\S+)$',
  multiLine: true,
);

String _readVersion(String pubspecPath) {
  final content = File(pubspecPath).readAsStringSync();
  final match = _versionRegex.firstMatch(content);
  if (match == null) {
    throw 'Could not find version in $pubspecPath';
  }
  return match.group(1)!;
}

final _slangConstraintRegex = RegExp(
  r"^  slang: '(.+)'$",
  multiLine: true,
);

String _readSlangConstraint(String pubspecPath) {
  final content = File(pubspecPath).readAsStringSync();
  final match = _slangConstraintRegex.firstMatch(content);
  if (match == null) {
    throw 'Could not find slang dependency in $pubspecPath';
  }
  return match.group(1)!;
}

/// For version 1.2.3 the expected constraint is ">=1.2.3 <1.3.0".
String _expectedConstraint(String version) {
  final parts = version.split('.');
  if (parts.length != 3) {
    throw 'Unexpected version format: $version';
  }
  final major = parts[0];
  final minor = int.parse(parts[1]);
  return '>=$version <$major.${minor + 1}.0';
}

void _setOrigin(String url) {
  _git(['remote', 'set-url', 'origin', url]);
  print('origin -> $url');
}

void _git(List<String> args) {
  final result = Process.runSync('git', args);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw 'git ${args.join(' ')} failed with exit code ${result.exitCode}';
  }
}
