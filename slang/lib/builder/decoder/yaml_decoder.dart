import 'package:slang/builder/decoder/base_decoder.dart';
import 'package:slang/builder/utils/yaml_utils.dart';
import 'package:yaml/yaml.dart';

class YamlDecoder extends BaseDecoder {
  @override
  Map<String, dynamic> decode(String raw) {
    return YamlUtils.deepCast(loadYaml(raw));
  }
}
