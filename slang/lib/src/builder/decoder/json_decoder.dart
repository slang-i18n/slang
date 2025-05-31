import 'dart:convert';

import 'package:slang/src/builder/decoder/base_decoder.dart';

class JsonDecoder implements BaseDecoder {
  const JsonDecoder();

  @override
  Map<String, dynamic> decode(String raw) {
    return json.decode(raw);
  }
}
