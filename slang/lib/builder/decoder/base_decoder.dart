import 'package:slang/builder/decoder/csv_decoder.dart';
import 'package:slang/builder/decoder/json_decoder.dart';
import 'package:slang/builder/decoder/yaml_decoder.dart';
import 'package:slang/builder/model/build_config.dart';

abstract class BaseDecoder {
  /// Transforms the raw string (json, yaml, csv) to a standardized map structure
  /// of Map<String, dynamic>
  ///
  /// Children are Map<String, dynamic>, List<dynamic> or String
  ///
  /// No case transformations, etc! Only the raw data represented as a tree.
  Map<String, dynamic> decode(String raw);

  /// Returns the decoder of the specified file type
  static BaseDecoder getDecoderOfFileType(FileType fileType) {
    switch (fileType) {
      case FileType.json:
        return JsonDecoder();
      case FileType.yaml:
        return YamlDecoder();
      case FileType.csv:
        return CsvDecoder();
    }
  }
}
