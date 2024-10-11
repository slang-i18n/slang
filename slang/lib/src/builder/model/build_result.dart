import 'package:slang/src/builder/model/i18n_locale.dart';

/// the resulting output strings
/// It can either be rendered as a single file
/// or as multiple files.
class BuildResult {
  final String main;
  final Map<I18nLocale, String> translations;

  BuildResult({
    required this.main,
    required this.translations,
  });
}
