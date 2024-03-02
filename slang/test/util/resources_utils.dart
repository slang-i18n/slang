import 'dart:io';

String loadResource(String path) {
  return File('$_testDirectory/integration/resources/$path').readAsStringSync();
}

// From https://github.com/flutter/flutter/issues/20907#issuecomment-466185328
final _testDirectory =
    '${Directory.current.path.replaceAll('\\', '/')}/${Directory.current.path.endsWith('test') ? '' : 'test'}';
