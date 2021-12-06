import 'dart:io';

String loadAsset(String path) {
  return File("$_testDirectory/resources/$path").readAsStringSync();
}

// From https://github.com/flutter/flutter/issues/20907#issuecomment-466185328
final _testDirectory = Directory.current.path.replaceAll('\\', '/') +
    '/' +
    (Directory.current.path.endsWith('test') ? '' : 'test');
