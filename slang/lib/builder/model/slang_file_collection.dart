import 'package:slang/builder/model/i18n_locale.dart';
import 'package:slang/builder/model/raw_config.dart';
import 'package:slang/builder/utils/path_utils.dart';

class SlangFileCollection {
  final RawConfig config;
  final List<TranslationFile> files;

  SlangFileCollection({
    required this.config,
    required this.files,
  });

  String determineOutputPath() {
    if (config.outputDirectory != null) {
      // output directory specified, use this path instead
      return config.outputDirectory! + '/' + config.outputFileName;
    } else {
      // use the directory of the first (random) translation file
      final tempPath = files.first.path;
      if (config.flutterIntegration && !tempPath.startsWith('lib/')) {
        // In Flutter environment, only files inside 'lib' matter
        // Generate to lib/gen/<fileName> by default.
        return 'lib/gen/${config.outputFileName}';
      } else {
        // By default, generate to the same directory as the translation file
        return PathUtils.replaceFileName(
          path: tempPath,
          newFileName: config.outputFileName,
          pathSeparator: '/',
        );
      }
    }
  }
}

class TranslationFile {
  final String path;
  final I18nLocale locale;
  final String namespace;
  final FileReader read;

  TranslationFile({
    required this.path,
    required this.locale,
    required this.namespace,
    required this.read,
  });
}

/// Similar to [TranslationFile], but without locale and namespace
class PlainTranslationFile {
  final String path;
  final FileReader read;

  PlainTranslationFile({
    required this.path,
    required this.read,
  });
}

typedef FileReader = Future<String> Function();
