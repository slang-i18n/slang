import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:slang/src/builder/model/i18n_locale.dart';
import 'package:slang/src/builder/model/slang_file_collection.dart';

void runConfigure(
  SlangFileCollection fileCollection, {
  List<String>? arguments,
}) {
  final locales = getLocales(fileCollection);
  final sourceDirs = parseSourceDirs(arguments);
  final plistPaths = getPlistPaths(sourceDirs);

  for (final path in plistPaths) {
    final file = File(path);
    if (!file.existsSync()) {
      print('File not found: $path');
      continue;
    }

    final updated =
        updatePlist(locales: locales, content: file.readAsStringSync());
    file.writeAsStringSync(updated);
    print('Updated: $path');
  }
}

final _plistRegex = RegExp(
    r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
    dotAll: true);

String updatePlist({
  required Set<I18nLocale> locales,
  required String content,
}) {
  final lines = LineSplitter().convert(content);

  // Determine tab based on first <key> tag
  final tab = lines
          .firstWhereOrNull((element) => element.contains('<key>'))
          ?.split('<key>')
          .first ??
      '\t';

  final localeStrings = locales
      .map((locale) => '$tab$tab<string>${locale.languageTag}</string>')
      .join('\n');

  if (_plistRegex.hasMatch(content)) {
    // Replace existing CFBundleLocalizations array
    return content.replaceFirstMapped(_plistRegex, (match) {
      return '<key>CFBundleLocalizations</key>\n$tab<array>\n$localeStrings\n$tab</array>';
    });
  } else {
    // Add before the closing dict tag
    final closingDictIndex = content.lastIndexOf('</dict>');
    if (closingDictIndex == -1) {
      throw Exception('Invalid Info.plist format: missing closing </dict> tag');
    }

    final insertion =
        '$tab<key>CFBundleLocalizations</key>\n$tab<array>\n$localeStrings\n$tab</array>\n';

    return content.substring(0, closingDictIndex) +
        insertion +
        content.substring(closingDictIndex);
  }
}

Set<I18nLocale> getLocales(SlangFileCollection fileCollection) {
  final locales = <I18nLocale>[];
  for (final file in fileCollection.files) {
    locales.add(file.locale);
  }
  locales.sort((a, b) => a.languageTag.compareTo(b.languageTag));
  return locales.toSet();
}

List<String> parseSourceDirs(List<String>? arguments) {
  if (arguments == null) return ['.'];
  for (final a in arguments) {
    if (a.startsWith('--source-dirs=')) {
      return a.substring(14).split(',').map((s) => s.trim()).toList();
    }
  }
  return ['.'];
}

List<String> getPlistPaths(List<String> sourceDirs) {
  final plistPaths = <String>[];
  for (final sourceDir in sourceDirs) {
    plistPaths.addAll([
      '$sourceDir/ios/Runner/Info.plist',
      '$sourceDir/macos/Runner/Info.plist',
    ]);
  }
  return plistPaths;
}
