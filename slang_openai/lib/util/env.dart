import 'package:dotenv/dotenv.dart';

class Env {
  static late final DotEnv _env;

  static void load() {
    _env = DotEnv(includePlatformEnvironment: true)..load();
  }

  static String? get openAiApiKey => _env['OPENAI_API_KEY'];

  static String? get openrouterApiKey => _env['OPENROUTER_API_KEY'];
}
