import 'dart:convert';

import 'package:fast_i18n/src/decoder/base_decoder.dart';

class JsonDecoder extends BaseDecoder {
  @override
  Map<String, dynamic> decode(String raw) {
    return json.decode(raw);
  }
}
