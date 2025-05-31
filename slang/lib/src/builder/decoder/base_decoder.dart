import 'package:slang/src/builder/decoder/arb_decoder.dart';
import 'package:slang/src/builder/decoder/csv_decoder.dart';
import 'package:slang/src/builder/decoder/json_decoder.dart';
import 'package:slang/src/builder/decoder/yaml_decoder.dart';

abstract class BaseDecoder {
  /// Transforms the raw string (json, yaml, csv)
  /// to a standardized map structure of `Map<String, dynamic>`
  ///
  /// Children are `Map<String, dynamic>`, `List<dynamic>` or `String`
  ///
  /// No case transformations, etc! Only the raw data represented as a tree.
  Map<String, dynamic> decode(String raw);
}

abstract class DecoderHandler {
  /// Decodes the raw string based on the type hint.
  ///
  /// The type hint is used to determine which decoder to use.
  Map<String, dynamic> decode(String raw, String typeHint);
}

/// Decodes with the built-in decoders based on the file type.
class DefaultDecoder implements DecoderHandler {
  static const instance = DefaultDecoder();

  const DefaultDecoder();

  @override
  Map<String, dynamic> decode(String raw, String typeHint) {
    final BaseDecoder decoder;
    switch (typeHint) {
      case 'json':
        decoder = const JsonDecoder();
        break;
      case 'yaml':
        decoder = const YamlDecoder();
        break;
      case 'csv':
        decoder = const CsvDecoder();
        break;
      case 'arb':
        decoder = const ArbDecoder();
        break;
      default:
        throw 'Unknown type hint: $typeHint. Supported types are: json, yaml, csv, arb.';
    }
    return decoder.decode(raw);
  }
}
