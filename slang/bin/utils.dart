// This file is not meant to be executed

import 'dart:convert';

import 'package:json2yaml/json2yaml.dart';
import 'package:slang/builder/model/enums.dart';
import 'package:slang/builder/utils/file_utils.dart';

const String INFO_KEY = '@@info';

void writeFile({
  required FileType fileType,
  required String path,
  required Map<String, dynamic> content,
}) {
  final String encodedContent;
  if (fileType == FileType.yaml) {
    if (content.containsKey(INFO_KEY)) {
      // workaround
      // https://github.com/alexei-sintotski/json2yaml/issues/23
      content = {
        '"$INFO_KEY"': content[INFO_KEY],
        ...content..remove(INFO_KEY),
      };
    }
    encodedContent = json2yaml(content, yamlStyle: YamlStyle.generic);
  } else {
    encodedContent = JsonEncoder.withIndent('  ').convert(content);
  }

  FileUtils.writeFile(
    path: path,
    content: encodedContent,
  );
}
