import 'package:fast_i18n/src/decoder/base_decoder.dart';
import 'package:fast_i18n/src/utils/yaml_utils.dart';
import 'package:yaml/yaml.dart';

class YamlDecoder extends BaseDecoder {
  @override
  Map<String, dynamic> decode(String raw) {
    return YamlUtils.deepCast(loadYaml(raw));
  }
}
