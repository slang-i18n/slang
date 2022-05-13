import 'dart:convert';

import 'package:slang/builder/decoder/base_decoder.dart';

class JsonDecoder extends BaseDecoder {
  @override
  Map<String, dynamic> decode(String raw) {
    return json.decode(raw);
  }
}
