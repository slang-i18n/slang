import 'package:slang/builder/model/build_result.dart';
import 'package:slang/builder/model/generate_config.dart';
import 'package:slang/builder/model/i18n_data.dart';
import 'package:slang/src/builder/generator/generate_header.dart';
import 'package:slang/src/builder/generator/generate_translations.dart';

class Generator {
  /// main generate function
  /// returns a string representing the content of the .g.dart file
  static BuildResult generate({
    required GenerateConfig config,
    required List<I18nData> translations,
  }) {
    final header = generateHeader(config, translations);
    final list = {
      for (final t in translations) t.locale: generateTranslations(config, t),
    };
    final String? flatMap;
    if (config.renderFlatMap) {
      flatMap = generateTranslationMap(config, translations);
    } else {
      flatMap = null;
    }

    return BuildResult(
      header: header,
      translations: list,
      flatMap: flatMap,
    );
  }
}
