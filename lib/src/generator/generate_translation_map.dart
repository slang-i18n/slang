part of 'generate_translations.dart';

String generateTranslationMap(
  I18nConfig config,
  List<I18nData> translations,
) {
  final buffer = StringBuffer();

  if (config.outputFormat == OutputFormat.multipleFiles) {
    // this is a part file
    buffer.writeln('part of \'${config.baseName}.g.dart\';');
    buffer.writeln();
  }

  buffer.writeln('/// Flat map(s) containing all translations.');
  buffer.writeln(
      '/// Only for edge cases! For simple maps, use the map function of this library.');

  for (I18nData localeData in translations) {
    final language =
        localeData.locale.language ?? I18nLocale.UNDEFINED_LANGUAGE;
    final hasPluralResolver = config.hasPluralResolver(language);

    buffer.writeln();
    buffer.writeln(
        'extension on ${getClassNameRoot(baseName: config.baseName, locale: localeData.locale, visibility: config.translationClassVisibility)} {');
    buffer.writeln('\tMap<String, dynamic> _buildFlatMap() {');

    buffer.writeln('\t\treturn <String, dynamic>{');
    _generateTranslationMapRecursive(
      buffer: buffer,
      curr: localeData.root,
      config: config,
      hasPluralResolver: hasPluralResolver,
      language: language,
    );
    buffer.writeln('\t\t};');
    buffer.writeln('\t}');
    buffer.writeln('}');
  }

  return buffer.toString();
}

_generateTranslationMapRecursive({
  required StringBuffer buffer,
  required Node curr,
  required I18nConfig config,
  required bool hasPluralResolver,
  required String language,
}) {
  if (curr is TextNode) {
    if (curr.params.isEmpty) {
      buffer.writeln('\t\t\t\'${curr.path}\': \'${curr.content}\',');
    } else {
      buffer.writeln(
          '\t\t\t\'${curr.path}\': ${_toParameterList(curr.params, curr.paramTypeMap)} => \'${curr.content}\',');
    }
  } else if (curr is ListNode) {
    // recursive
    curr.entries.forEach((child) {
      _generateTranslationMapRecursive(
        buffer: buffer,
        curr: child,
        config: config,
        hasPluralResolver: hasPluralResolver,
        language: language,
      );
    });
  } else if (curr is ObjectNode) {
    // recursive
    curr.entries.values.forEach((child) {
      _generateTranslationMapRecursive(
        buffer: buffer,
        curr: child,
        config: config,
        hasPluralResolver: hasPluralResolver,
        language: language,
      );
    });
  } else if (curr is PluralNode) {
    buffer.write('\t\t\t\'${curr.path}\': ');
    _addPluralizationCall(
      buffer: buffer,
      config: config,
      hasPluralResolver: hasPluralResolver,
      language: language,
      node: curr,
      depth: 2,
    );
  } else if (curr is ContextNode) {
    buffer.write('\t\t\t\'${curr.path}\': ');
    _addContextCall(
      buffer: buffer,
      config: config,
      node: curr,
      depth: 2,
    );
  } else {
    throw 'This should not happen';
  }
}
