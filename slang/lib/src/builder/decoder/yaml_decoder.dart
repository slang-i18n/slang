import 'package:slang/src/builder/decoder/base_decoder.dart';
import 'package:slang/src/builder/utils/map_utils.dart';
import 'package:yaml/yaml.dart';

class YamlDecoder extends BaseDecoder {
  @override
  Map<String, dynamic> decode(String raw) {
    final converted = loadYaml(raw);
    if (converted == null) {
      throw Exception('Failed to decode YAML:\n${raw.substring(0, 200)}');
    }
    return MapUtils.deepCast(converted);
  }
}
