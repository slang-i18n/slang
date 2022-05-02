import 'package:fast_i18n/src/model/i18n_locale.dart';

class StatsResult {
  final Map<I18nLocale, StatsLocaleResult> localeStats;
  final StatsLocaleResult globalStats;

  StatsResult({
    required this.localeStats,
    required this.globalStats,
  });

  void printResult() {
    final specialCharacters = ',.?!\'¿¡';
    localeStats.forEach((locale, stats) {
      print('[${locale.languageTag}]');
      print(' - ${stats.keyCount} keys (including intermediate keys)');
      print(' - ${stats.translationCount} translations (leaves only)');
      print(' - ${stats.wordCount} words');
      print(' - ${stats.characterCount} characters (ex. [$specialCharacters])');
    });
    print('[total]');
    print(' - ${globalStats.keyCount} keys (including intermediate keys)');
    print(' - ${globalStats.translationCount} translations (leaves only)');
    print(' - ${globalStats.wordCount} words');
    print(
        ' - ${globalStats.characterCount} characters (ex. [$specialCharacters])');
  }
}

class StatsLocaleResult {
  final int keyCount;
  final int translationCount;
  final int wordCount;
  final int characterCount;

  StatsLocaleResult({
    required this.keyCount,
    required this.translationCount,
    required this.wordCount,
    required this.characterCount,
  });
}
