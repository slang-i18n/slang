/// Contains a reference to a json, yaml or csv file
/// Abstracted to be used by custom runner and by build_runner
class TranslationFile {
  final String path; // all forward slash
  final FileReader read;

  TranslationFile({
    required this.path,
    required this.read,
  });
}

typedef FileReader = Future<String> Function();
