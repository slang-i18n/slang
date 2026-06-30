import 'dart:io';

/// Release script for slang.
///
/// Usage: fvm dart run release.dart
///
/// Steps:
///  1. Sync slang_flutter / slang_build_runner to slang's version: whenever they
///     differ from slang, update their pubspec version, their slang constraint
///     and the first CHANGELOG heading.
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

  bool changed = false;
  for (final pkg in ['slang_flutter', 'slang_build_runner']) {
    final pubspec = '$pkg/pubspec.yaml';

    final pkgVersion = _readVersion(pubspec);
    if (pkgVersion != version) {
      print('$pkg: version $pkgVersion -> $version');
      _setVersion(pubspec, version);
      _setChangelogVersion('$pkg/CHANGELOG.md', version);
      changed = true;
    }

    final constraint = _readSlangConstraint(pubspec);
    if (constraint != expectedConstraint) {
      print('$pkg: slang constraint "$constraint" -> "$expectedConstraint"');
      _setSlangConstraint(pubspec, expectedConstraint);
      changed = true;
    }
  }

  if (changed) {
    print('Updated versions and/or constraints. Please commit the changes and re-run the script.');
    return;
  }

  print('All versions and constraints are in sync.');

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

void _setVersion(String pubspecPath, String version) {
  final file = File(pubspecPath);
  final content = file.readAsStringSync();
  if (!_versionRegex.hasMatch(content)) {
    throw 'Could not find version in $pubspecPath';
  }
  file.writeAsStringSync(content.replaceFirst(_versionRegex, 'version: $version'));
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

void _setSlangConstraint(String pubspecPath, String constraint) {
  final file = File(pubspecPath);
  final content = file.readAsStringSync();
  if (!_slangConstraintRegex.hasMatch(content)) {
    throw 'Could not find slang dependency in $pubspecPath';
  }
  file.writeAsStringSync(
    content.replaceFirst(_slangConstraintRegex, "  slang: '$constraint'"),
  );
}

final _changelogHeadingRegex = RegExp(
  r'^## \S+$',
  multiLine: true,
);

/// Replaces the changelog's first `## <version>` heading with [version].
///
/// Sub-package changelogs only point to the slang changelog, so a single
/// heading is kept up to date rather than accumulating entries.
void _setChangelogVersion(String changelogPath, String version) {
  final file = File(changelogPath);
  final content = file.readAsStringSync();
  if (!_changelogHeadingRegex.hasMatch(content)) {
    throw 'Could not find a version heading in $changelogPath';
  }
  file.writeAsStringSync(
    content.replaceFirst(_changelogHeadingRegex, '## $version'),
  );
  print('$changelogPath: set heading to $version');
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
