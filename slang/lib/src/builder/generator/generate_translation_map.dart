part of 'generate_translations.dart';

const _maxSwitchCasesPerBlock = 512;

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
  buffer.writeln('///');
  buffer.writeln(
      '/// The Dart AOT compiler has issues with very large switch statements,');
  buffer.writeln(
      '/// so the map is split into smaller functions ($_maxSwitchCasesPerBlock entries each).');
  buffer.writeln(
      'extension on ${localeData.base ? config.className : getClassNameRoot(className: config.className, locale: localeData.locale)} {');

  final flatList = _toFlatList(localeData.root);
  final flatListSplits = <List<Node>>[];
  for (var i = 0; i < flatList.length; i += _maxSwitchCasesPerBlock) {
    flatListSplits.add(flatList.sublist(
      i,
      min(i + _maxSwitchCasesPerBlock, flatList.length),
    ));
  }

  buffer.writeln('\tdynamic _flatMapFunction(String path) {');
  buffer.write('\t\treturn ');
  for (var i = 0; i < flatListSplits.length; i++) {
    if (i == 0) {
      buffer.write('_flatMapFunction\$$i(path)');
    } else {
      buffer.write('\n\t\t\t?? _flatMapFunction\$$i(path)');
    }
  }
  buffer.writeln(';');
  buffer.writeln('\t}');

  // Generate split functions
  for (var i = 0; i < flatListSplits.length; i++) {
    buffer.writeln();
    buffer.writeln('\tdynamic _flatMapFunction\$$i(String path) {');
    buffer.writeln('\t\tswitch (path) {');

    _generateTranslationMap(
      buffer: buffer,
      flatList: flatListSplits[i],
      config: config,
      language: localeData.locale.language,
    );

    buffer.writeln('\t\t\tdefault: return null;');
    buffer.writeln('\t\t}');
    buffer.writeln('\t}');
  }

  buffer.writeln('}');

  return buffer.toString();
}

void _generateTranslationMap({
  required StringBuffer buffer,
  required Iterable<Node> flatList,
  required GenerateConfig config,
  required String language,
}) {
  for (final curr in flatList) {
    if (curr is StringTextNode) {
      final translationOverrides = config.translationOverrides
          ? 'TranslationOverrides.string(_root.\$meta, \'${curr.path}\', ${_toParameterMap(curr.params)}) ?? '
          : '';
      final stringLiteral =
          getStringLiteral(curr.content, curr.links.length, config.obfuscation);
      if (curr.params.isEmpty) {
        buffer.writeln(
            '\t\t\tcase \'${curr.path}\': return $translationOverrides$stringLiteral;');
      } else {
        buffer.writeln(
            '\t\t\tcase \'${curr.path}\': return ${_toParameterList(curr.params, curr.paramTypeMap)} => $translationOverrides$stringLiteral;');
      }
    } else if (curr is RichTextNode) {
      buffer.write('\t\t\tcase \'${curr.path}\': return ');
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
    } else if (curr is PluralNode) {
      buffer.write('\t\t\tcase \'${curr.path}\': return ');
      _addPluralCall(
        buffer: buffer,
        config: config,
        language: language,
        node: curr,
        depth: 2,
        forceSemicolon: true,
      );
    } else if (curr is ContextNode) {
      buffer.write('\t\t\tcase \'${curr.path}\': return ');
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
}

List<Node> _toFlatList(ObjectNode root) {
  final result = <Node>[];

  void flatten(Node node) {
    if (node is ListNode) {
      for (final entry in node.entries) {
        flatten(entry);
      }
    } else if (node is ObjectNode) {
      for (final value in node.values) {
        flatten(value);
      }
    } else {
      result.add(node);
    }
  }

  for (final value in root.values) {
    flatten(value);
  }

  return result;
}
