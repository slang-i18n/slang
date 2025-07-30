import 'package:slang/src/builder/generator/generate_header.dart';
import 'package:slang/src/builder/generator/generate_translations.dart';
import 'package:slang/src/builder/model/build_result.dart';
import 'package:slang/src/builder/model/generate_config.dart';
import 'package:slang/src/builder/model/i18n_data.dart';

class Generator {
  /// main generate function
  /// returns a string representing the content of the .g.dart file
  static BuildResult generate({
    required GenerateConfig config,
    required List<I18nData> translations,
  }) {
    return BuildResult(
      main: generateHeader(config, translations),
      translations: {
        for (final t in translations)
          t.locale: generateTranslations(config, t, translations),
      },
    );
  }
}
