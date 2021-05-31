import 'package:fast_i18n/src/model/build_config.dart';

/// result of the build.yaml parser
class YamlParseResult {
  final bool parsed;
  final BuildConfig config;

  YamlParseResult({this.parsed, this.config});
}
