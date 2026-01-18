// ignore: implementation_imports
import 'package:slang/src/builder/builder/slang_file_collection_builder.dart';

// ignore: implementation_imports
import 'package:slang/src/builder/builder/translation_map_builder.dart';

// ignore: implementation_imports
import 'package:slang/src/builder/model/i18n_locale.dart';

// ignore: implementation_imports
import 'package:slang/src/runner/apply.dart';

// ignore: implementation_imports
import 'package:slang/src/runner/generate.dart';

Future<void> apply({
  required I18nLocale locale,
  required Map<String, dynamic> translations,
}) async {
  final fileCollection = SlangFileCollectionBuilder.readFromFileSystem(
    verbose: false,
  );

  final translationMap = await TranslationMapBuilder.build(
    fileCollection: fileCollection,
  );

  await applyTranslationsForOneLocale(
    fileCollection: fileCollection,
    applyLocale: locale,
    baseTranslations: translationMap[fileCollection.config.baseLocale]!,
    newTranslations: translations,
  );

  // Generate after applying with new translations
  await generateTranslations(
    fileCollection: SlangFileCollectionBuilder.readFromFileSystem(
      verbose: false,
    ),
  );
}
