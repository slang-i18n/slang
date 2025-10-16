part of 'generate_translations.dart';

/// Generates the flat map(s) containing all translations for one locale.
String generateTranslationMap(
  GenerateConfig config,
  I18nData localeData,
) {
  final buffer = StringBuffer();

  buffer.writeln(
      '/// The flat map containing all translations for locale <${localeData.locale.languageTag}>.');
  buffer.writeln(
      '/// Only for edge cases! For simple maps, use the map function of this library.');
  buffer.writeln(
      '/// Note: We use a HashMap because Dart seems to be unable to compile large switch statements.');
  buffer.writeln('Map<String, dynamic>? _map;');
  buffer.writeln();

  buffer.writeln(
      'extension on ${localeData.base ? config.className : getClassNameRoot(className: config.className, locale: localeData.locale)} {');
  buffer.writeln('\tdynamic _flatMapFunction(String path) {');
  buffer.writeln('\t\tfinal map = _map ?? _initFlatMap();');
  buffer.writeln('\t\treturn map[path];');
  buffer.writeln('\t}');
  buffer.writeln();
  buffer.writeln('\t/// Initializes the flat map and returns it.');
  buffer.writeln('\tMap<String, dynamic> _initFlatMap() {');
  buffer.writeln('\t\tfinal map = <String, dynamic>{};');

  _generateTranslationMapRecursive(
    buffer: buffer,
    curr: localeData.root,
    config: config,
    language: localeData.locale.language,
  );

  buffer.writeln();
  buffer.writeln('\t\t_map = map;');
  buffer.writeln('\t\treturn map;');
  buffer.writeln('\t}');
  buffer.writeln('}');

  return buffer.toString();
}

void _generateTranslationMapRecursive({
  required StringBuffer buffer,
  required Node curr,
  required GenerateConfig config,
  required String language,
}) {
  if (curr is StringTextNode) {
    final translationOverrides = config.translationOverrides
        ? 'TranslationOverrides.string(_root.\$meta, \'${curr.path}\', ${_toParameterMap(curr.params)}) ?? '
        : '';
    final stringLiteral =
        getStringLiteral(curr.content, curr.links.length, config.obfuscation);
    if (curr.params.isEmpty) {
      buffer.writeln(
          '\t\tmap[\'${curr.path}\'] = $translationOverrides$stringLiteral;');
    } else {
      buffer.writeln(
          '\t\tmap[\'${curr.path}\'] = ${_toParameterList(curr.params, curr.paramTypeMap)} => $translationOverrides$stringLiteral;');
    }
  } else if (curr is RichTextNode) {
    buffer.write('\t\tmap[\'${curr.path}\'] = ');
    _addRichTextCall(
      buffer: buffer,
      config: config,
      node: curr,
      includeParameters: true,
      variableNameResolver: null,
      forceArrow: false,
      depth: 2,
      forceSemicolon: true,
    );
  } else if (curr is ListNode) {
    // recursive
    for (final child in curr.entries) {
      _generateTranslationMapRecursive(
        buffer: buffer,
        curr: child,
        config: config,
        language: language,
      );
    }
  } else if (curr is ObjectNode) {
    // recursive
    for (final child in curr.entries.values) {
      _generateTranslationMapRecursive(
        buffer: buffer,
        curr: child,
        config: config,
        language: language,
      );
    }
  } else if (curr is PluralNode) {
    buffer.write('\t\tmap[\'${curr.path}\'] = ');
    _addPluralCall(
      buffer: buffer,
      config: config,
      language: language,
      node: curr,
      depth: 2,
      forceSemicolon: true,
    );
  } else if (curr is ContextNode) {
    buffer.write('\t\tmap[\'${curr.path}\'] = ');
    _addContextCall(
      buffer: buffer,
      config: config,
      node: curr,
      depth: 2,
      forceSemicolon: true,
    );
  } else {
    throw 'This should not happen';
  }
}
