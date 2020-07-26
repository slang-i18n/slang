final specialRegex = RegExp(r'[^a-zA-Z0-9]');

class I18nData {
  final String baseName;
  final bool base;
  final String locale;
  final Map<String, Value> entries;

  I18nData(this.baseName, this.locale, this.entries) : base = locale.isEmpty;
}

class Value {}

class ChildNode extends Value {
  final Map<String, Value> entries;

  ChildNode(this.entries);

  @override
  String toString() => entries.toString();
}

class Text extends Value {

  final String content;
  final List<String> params;

  Text(this.content) : params = _findArguments(content);

  @override
  String toString() => '$params => $content';
}

List<String> _findArguments(String content) {
  String s = content.replaceAll('\\\$', ''); // remove \$
  List<String> arguments = [];
  int indexStart = s.indexOf('\$');
  while (indexStart != -1) {

    if (indexStart == s.length - 1)
      break;

    int indexEnd = s.indexOf(specialRegex, indexStart + 1);
    if (indexEnd != -1) {
      arguments.add(s.substring(indexStart+1, indexEnd));
      s = s.substring(indexEnd);
      indexStart = s.indexOf('\$');
    } else {
      arguments.add(s.substring(indexStart+1));
      break;
    }
  }

  return arguments;
}