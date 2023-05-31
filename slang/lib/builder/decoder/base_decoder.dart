import 'package:slang/builder/decoder/csv_decoder.dart';
import 'package:slang/builder/decoder/json_decoder.dart';
import 'package:slang/builder/decoder/yaml_decoder.dart';
import 'package:slang/builder/model/enums.dart';

abstract class BaseDecoder {
  /// Transforms the raw string (json, yaml, csv)
  /// to a standardized map structure of Map<String, dynamic>
  ///
  /// Children are Map<String, dynamic>, List<dynamic> or String
  ///
  /// No case transformations, etc! Only the raw data represented as a tree.
  Map<String, dynamic> decode(String raw);

  /// Decodes with the specified file type
  static Map<String, dynamic> decodeWithFileType(
    FileType fileType,
    String raw,
  ) {
    final BaseDecoder decoder;
    switch (fileType) {
      case FileType.json:
        decoder = JsonDecoder();
        break;
      case FileType.yaml:
        decoder = YamlDecoder();
        break;
      case FileType.csv:
        decoder = CsvDecoder();
        break;
    }
    return decoder.decode(raw);
  }
}
