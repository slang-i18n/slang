///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:flutter/widgets.dart';
import 'package:slang/generated.dart';
import 'strings_b.g.dart';

// Path: <root>
class TranslationsDe implements Translations {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  TranslationsDe(
      {Map<String, Node>? overrides,
      PluralResolver? cardinalResolver,
      PluralResolver? ordinalResolver})
      : assert(overrides == null,
            'Set "translation_overrides: true" in order to enable this feature.'),
        $meta = TranslationMetadata(
          locale: AppLocale.de,
          overrides: overrides ?? {},
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
        ) {
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <de>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  @override
  dynamic operator [](String key) => $meta.getTranslation(key);

  late final TranslationsDe _root = this; // ignore: unused_field

  // Translations
  @override
  String get title => 'Package B (de)';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on TranslationsDe {
  dynamic _flatMapFunction(String path) {
    switch (path) {
      case 'title':
        return 'Package B (de)';
      default:
        return null;
    }
  }
}
