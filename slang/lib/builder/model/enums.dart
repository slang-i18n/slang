enum FileType { json, yaml, csv, arb }

enum FallbackStrategy { none, baseLocale, baseLocaleEmptyString }

/// Similar to [FallbackStrategy] but [FallbackStrategy.baseLocaleEmptyString]
/// has been already handled in the previous step.
enum GenerateFallbackStrategy { none, baseLocale }

enum OutputFormat { singleFile, multipleFiles }

enum StringInterpolation { dart, braces, doubleBraces }

enum TranslationClassVisibility { private, public }

enum CaseStyle { camel, pascal, snake }

enum PluralAuto { off, cardinal, ordinal }

extension FallbackStrategyExt on FallbackStrategy {
  GenerateFallbackStrategy toGenerateFallbackStrategy() {
    switch (this) {
      case FallbackStrategy.none:
        return GenerateFallbackStrategy.none;
      case FallbackStrategy.baseLocale:
        return GenerateFallbackStrategy.baseLocale;
      case FallbackStrategy.baseLocaleEmptyString:
        return GenerateFallbackStrategy.baseLocale;
    }
  }
}
