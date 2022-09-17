import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/utils/map_utils.dart';
import 'package:yaml/yaml.dart';

class YamlDecoder extends BaseDecoder {
  @override
  Map<String, dynamic> decode(String raw) {
    return MapUtils.deepCast(loadYaml(raw));
  }
}
