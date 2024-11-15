import 'package:slang/src/builder/model/enums.dart';

class SanitizationConfig {
  static const bool defaultEnabled = true;
  static const String defaultPrefix = 'k';
  static const CaseStyle defaultCaseStyle = CaseStyle.camel;

  final bool enabled;
  final String prefix;
  final CaseStyle? caseStyle;

  const SanitizationConfig({
    required this.enabled,
    required this.prefix,
    required this.caseStyle,
  });
}
