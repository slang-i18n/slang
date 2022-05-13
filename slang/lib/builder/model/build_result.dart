import 'package:slang/builder/model/i18n_locale.dart';

/// the resulting output strings
/// It can either be rendered as a single file
/// or as multiple files.
class BuildResult {
  final String header;
  final Map<I18nLocale, String> translations;
  final String? flatMap;

  BuildResult({
    required this.header,
    required this.translations,
    required this.flatMap,
  });

  String joinAsSingleOutput() {
    final buffer = StringBuffer();
    buffer.writeln(header);
    buffer.writeln('// translations');
    for (final localeTranslations in translations.values) {
      buffer.write(localeTranslations);
    }
    if (flatMap != null) {
      buffer.writeln();
      buffer.write(flatMap);
    }
    return buffer.toString();
  }
}
