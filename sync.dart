import 'dart:io';

/// Sync script for slang.
///
/// Usage: fvm dart run sync.dart
///
/// Codeberg is the source of truth; commits merged on GitHub (pull requests)
/// end up on top of the Codeberg history:
///  1. Push local commits to Codeberg so nothing can get lost.
///  2. Point origin at GitHub and hard-reset local main to GitHub's main.
///  3. Restore the Codeberg remote and rebase, which replays the GitHub-only
///     commits on top of Codeberg's history.
///  4. Push the result to Codeberg (fast-forward) and force-push GitHub so it
///     mirrors the result (otherwise release.dart's push to GitHub would fail).
const _githubRemote = 'git@github.com:slang-i18n/slang.git';
const _codebergRemote = 'ssh://git@codeberg.org/Tienisto/slang.git';

void main() {
  // refuse to throw away uncommitted work.
  if (_gitOutput(['status', '--porcelain']).isNotEmpty) {
    throw 'Working tree is not clean. Commit or stash first.';
  }

  // 1. Local commits are safe on Codeberg before anything is discarded.
  _git(['push', 'origin', 'main']);

  // 2. "Force pull" GitHub: reset local main to GitHub's main.
  _setOrigin(_githubRemote);
  final String githubTip;
  try {
    _git(['fetch', 'origin', 'main']);
    githubTip = _gitOutput(['rev-parse', 'FETCH_HEAD']);
    _git(['reset', '--hard', githubTip]);
  } finally {
    _setOrigin(_codebergRemote);
  }

  // 3. Rebase the GitHub-only commits on top of Codeberg's history.
  // --no-fork-point: origin/main's reflog contains commits of both remotes,
  // and fork-point detection would silently drop the GitHub commits.
  _git(['fetch', 'origin', 'main']);
  _git(['rebase', '--no-fork-point', 'origin/main']);

  // 4. Sync both remotes with the result.
  _git(['push', 'origin', 'main']);
  _git(['push', '--force-with-lease=main:$githubTip', _githubRemote, 'main']);
  print('Done.');
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

String _gitOutput(List<String> args) {
  final result = Process.runSync('git', args);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw 'git ${args.join(' ')} failed with exit code ${result.exitCode}';
  }
  return (result.stdout as String).trim();
}
