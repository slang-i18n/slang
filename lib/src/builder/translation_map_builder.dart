import 'dart:convert';

import 'package:fast_i18n/src/model/build_config.dart';
import 'package:fast_i18n/src/utils/yaml_utils.dart';
import 'package:yaml/yaml.dart';

class TranslationMapBuilder {

  /// Parses the raw string and builds the map based on the tree
  /// in the translation file.
  static Map<String, dynamic> fromString(FileType fileType, String raw) {
    switch (fileType) {
      case FileType.json:
        return json.decode(raw);
      case FileType.yaml:
        return YamlUtils.deepCast(loadYaml(raw));
    }
  }
}