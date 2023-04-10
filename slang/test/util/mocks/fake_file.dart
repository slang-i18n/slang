import 'dart:convert';
import 'dart:io';

/// A fake implementation of [File] that holds a given content.
class FakeFile implements File {
  final String content;

  FakeFile(this.content);

  @override
  String readAsStringSync({Encoding encoding = utf8}) => content;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
